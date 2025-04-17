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
import AwsCommonRuntimeKit
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
            let modality = try model.getConverseModality()
            let parameters = modality.getConverseParameters()
            try parameters.validate(
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
                "Sending ConverseInput to BedrockRuntimeClient",
                metadata: [
                    "input.messages.count": "\(String(describing:input.messages!.count))",
                    "input.modelId": "\(String(describing:input.modelId!))",
                ]
            )
            let response: ConverseOutput = try await self.bedrockRuntimeClient.converse(input: input)

            logger.trace("Received response", metadata: ["response": "\(response)"])
            return try Message(response)
        } catch {
            try handleCommonError(error, context: "listing foundation models")
            throw BedrockServiceError.unknownError("\(error)")  // FIXME: handleCommonError will always throw
        }
    }

    /// Use Converse API with the ConverseBuilder
    /// - Parameters:
    ///   - builder: ConverseBuilder object
    /// - Throws: BedrockServiceError.invalidSDKResponse if the response body is missing
    /// - Returns: A ConverseReply object
    public func converse(with builder: ConverseBuilder) async throws -> ConverseReply {
        logger.trace("Conversing")
        do {
            var history = builder.history
            let userMessage = try builder.getUserMessage()
            history.append(userMessage)
            let assistantMessage = try await converse(
                with: builder.model,
                conversation: history,
                maxTokens: builder.maxTokens,
                temperature: builder.temperature,
                topP: builder.topP,
                stopSequences: builder.stopSequences,
                systemPrompts: builder.systemPrompts,
                tools: builder.tools
            )
            history.append(assistantMessage)
            logger.trace(
                "Received message",
                metadata: ["replyMessage": "\(assistantMessage)", "history.count": "\(history.count)"]
            )
            return try ConverseReply(history)
        } catch {
            logger.trace("Error while conversing", metadata: ["error": "\(error)"])
            throw error
        }
    }

    /// Use Converse API with the ConverseBuilder
    /// - Parameters:
    ///   - builder: ConverseBuilder object that will be updated to include the users message and the assistants reply.
    /// - Throws: BedrockServiceError.invalidSDKResponse if the response body is missing
    /// - Returns: A ConverseReply object
    public func converse(with builder: inout ConverseBuilder) async throws -> ConverseReply {
        let reply = try await converse(with: builder)
        builder = try builder.resetBuilder(reply.getHistory())
        return reply
    }
}
