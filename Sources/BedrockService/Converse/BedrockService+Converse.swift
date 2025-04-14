//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Foundation Models Playground open source project
//
// Copyright (c) 2025 Amazon.com, Inc. or its affiliates
//                    and the Swift Foundation Models Playground project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Foundation Models Playground project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@preconcurrency import AWSBedrockRuntime
import BedrockTypes
import Foundation

extension BedrockService {

    /// Converse with a model using the Bedrock Converse API
    /// - Parameters:
    ///   - model: The BedrockModel to converse with
    ///   - conversation: Array of previous messages in the conversation
    ///   - maxTokens: Optional maximum number of tokens to generate
    ///   - temperature: Optional temperature parameter for controlling randomness
    ///   - topP: Optional top-p parameter for nucleus sampling
    ///   - stopSequences: Optional array of sequences where generation should stop
    ///   - systemPrompts: Optional array of system prompts to guide the conversation
    ///   - tools: Optional array of tools the model can use
    /// - Throws: BedrockServiceError.notSupported for parameters or functionalities that are not supported
    ///           BedrockServiceError.invalidParameter for invalid parameters
    ///           BedrockServiceError.invalidPrompt if the prompt is empty or too long
    ///           BedrockServiceError.invalidModality for invalid modality from the selected model
    ///           BedrockServiceError.invalidSDKResponse if the response body is missing
    /// - Returns: A Message containing the model's response
    public func converse(
        with model: BedrockModel,
        conversation: [Message],
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequences: [String]? = nil,
        systemPrompts: [String]? = nil,
        tools: [Tool]? = nil
    ) async throws -> Message {
        do {
            let modality: ConverseModality = try model.getConverseModality()
            try validateConverseParams(
                modality: modality,
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                stopSequences: stopSequences
            )

            logger.trace(
                "Creating ConverseRequest",
                metadata: [
                    "model.name": "\(model.name)",
                    "model.id": "\(model.id)",
                    "conversation.count": "\(conversation.count)",
                    "maxToken": "\(String(describing: maxTokens))",
                    "temperature": "\(String(describing: temperature))",
                    "topP": "\(String(describing: topP))",
                    "stopSequences": "\(String(describing: stopSequences))",
                    "systemPrompts": "\(String(describing: systemPrompts))",
                    "tools": "\(String(describing: tools))",
                ]
            )
            let converseRequest = ConverseRequest(
                model: model,
                messages: conversation,
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                stopSequences: stopSequences,
                systemPrompts: systemPrompts,
                tools: tools
            )

            logger.trace("Creating ConverseInput")
            let input = try converseRequest.getConverseInput()
            logger.trace(
                "Created ConverseInput",
                metadata: [
                    "input.messages.count": "\(String(describing:input.messages!.count))",
                    "input.modelId": "\(String(describing:input.modelId!))",
                ]
            )

            let response = try await self.bedrockRuntimeClient.converse(input: input)
            logger.trace("Received response", metadata: ["response": "\(response)"])

            guard let converseOutput = response.output else {
                logger.trace(
                    "Invalid response",
                    metadata: [
                        "response": .string(String(describing: response)),
                        "hasOutput": .stringConvertible(response.output != nil),
                    ]
                )
                throw BedrockServiceError.invalidSDKResponse(
                    "Something went wrong while extracting ConverseOutput from response."
                )
            }
            let converseResponse = try ConverseResponse(converseOutput)
            return converseResponse.message
        } catch {
            logger.trace("Error while conversing", metadata: ["error": "\(error)"])
            throw error
        }
    }

    /// Use Converse API without needing to make Messages
    /// - Parameters:
    ///   - model: The BedrockModel to converse with
    ///   - prompt: Optional text prompt for the conversation
    ///   - imageFormat: Optional format for image input
    ///   - imageBytes: Optional base64 encoded image data
    ///   - history: Optional array of previous messages
    ///   - maxTokens: Optional maximum number of tokens to generate
    ///   - temperature: Optional temperature parameter for controlling randomness
    ///   - topP: Optional top-p parameter for nucleus sampling
    ///   - stopSequences: Optional array of sequences where generation should stop
    ///   - systemPrompts: Optional array of system prompts to guide the conversation
    ///   - tools: Optional array of tools the model can use
    ///   - toolResult: Optional result from a previous tool invocation
    /// - Throws: BedrockServiceError.notSupported for parameters or functionalities that are not supported
    ///           BedrockServiceError.invalidParameter for invalid parameters
    ///           BedrockServiceError.invalidPrompt if the prompt is empty or too long
    ///           BedrockServiceError.invalidModality for invalid modality from the selected model
    ///           BedrockServiceError.invalidSDKResponse if the response body is missing
    /// - Returns: A ConverseReply object
    public func converse(
        with model: BedrockModel,
        prompt: String? = nil,
        imageFormat: ImageBlock.Format? = nil,
        imageBytes: String? = nil,
        history: [Message] = [],
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequences: [String]? = nil,
        systemPrompts: [String]? = nil,
        tools: [Tool]? = nil,
        toolResult: ToolResultBlock? = nil
    ) async throws -> ConverseReply {
        logger.trace(
            "Conversing",
            metadata: [
                "model.id": .string(model.id),
                "model.modality": .string(model.modality.getName()),
                "prompt": .string(prompt ?? "No prompt"),
            ]
        )
        do {
            var messages = history
            let modality: ConverseModality = try model.getConverseModality()

            try validateConverseParams(modality: modality, prompt: prompt)

            if tools != nil || toolResult != nil {
                guard model.hasConverseModality(.toolUse) else {
                    throw BedrockServiceError.invalidModality(
                        model,
                        modality,
                        "This model does not support converse tool."
                    )
                }
            }

            if let toolResult {
                guard let _: [Tool] = tools else {
                    throw BedrockServiceError.invalidPrompt("Tool result is defined but tools are not.")
                }
                guard case .toolUse(_) = messages.last?.content.last else {
                    throw BedrockServiceError.invalidPrompt("Tool result is defined but last message is not tool use.")
                }
                messages.append(Message(toolResult))
            } else {
                guard let prompt = prompt else {
                    throw BedrockServiceError.invalidPrompt("Prompt is not defined.")
                }

                if let imageFormat, let imageBytes {
                    guard model.hasConverseModality(.vision) else {
                        throw BedrockServiceError.invalidModality(
                            model,
                            modality,
                            "This model does not support converse vision."
                        )
                    }
                    messages.append(
                        Message(prompt, imageFormat: imageFormat, imageBytes: imageBytes)
                    )
                } else {
                    messages.append(Message(prompt))
                }
            }
            let message = try await converse(
                with: model,
                conversation: messages,
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                stopSequences: stopSequences,
                systemPrompts: systemPrompts,
                tools: tools
            )
            messages.append(message)
            logger.trace(
                "Received message",
                metadata: ["replyMessage": "\(message)", "messages.count": "\(messages.count)"]
            )
            return try ConverseReply(messages)
        } catch {
            logger.trace("Error while conversing", metadata: ["error": "\(error)"])
            throw error
        }
    }

    /// Use Converse API without needing to make Messages
    /// - Parameters:
    ///   - model: The BedrockModel to converse with
    ///   - prompt: Optional text prompt for the conversation
    ///   - imageFormat: Optional format for image input
    ///   - imageBytes: Optional base64 encoded image data
    ///   - history: Array of previous messages that will be updated with the new conversation
    ///   - maxTokens: Optional maximum number of tokens to generate
    ///   - temperature: Optional temperature parameter for controlling randomness
    ///   - topP: Optional top-p parameter for nucleus sampling
    ///   - stopSequences: Optional array of sequences where generation should stop
    ///   - systemPrompts: Optional array of system prompts to guide the conversation
    ///   - tools: Optional array of tools the model can use
    ///   - toolResult: Optional result from a previous tool invocation
    /// - Throws: BedrockServiceError.notSupported for parameters or functionalities that are not supported
    ///           BedrockServiceError.invalidParameter for invalid parameters
    ///           BedrockServiceError.invalidPrompt if the prompt is empty or too long
    ///           BedrockServiceError.invalidModality for invalid modality from the selected model
    ///           BedrockServiceError.invalidSDKResponse if the response body is missing
    /// - Returns: A ConverseReply object
    public func converse(
        with model: BedrockModel,
        prompt: String? = nil,
        imageFormat: ImageBlock.Format? = nil,
        imageBytes: String? = nil,
        history: inout [Message],
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequences: [String]? = nil,
        systemPrompts: [String]? = nil,
        tools: [Tool]? = nil,
        toolResult: ToolResultBlock? = nil
    ) async throws -> ConverseReply {
        let reply = try await converse(
            with: model,
            prompt: prompt,
            imageFormat: imageFormat,
            imageBytes: imageBytes,
            history: history,
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            stopSequences: stopSequences,
            systemPrompts: systemPrompts,
            tools: tools,
            toolResult: toolResult
        )
        history = reply.getHistory()
        return reply
    }
}
