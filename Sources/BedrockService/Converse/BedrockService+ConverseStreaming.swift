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

    /// Converse with a model using the Bedrock Converse Streaming API
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
    /// - Returns: A stream of ConverseResponseStreaming objects
    public func converse(
        with model: BedrockModel,
        conversation: [Message],
        maxTokens: Int? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        stopSequences: [String]? = nil,
        systemPrompts: [String]? = nil,
        tools: [Tool]? = nil
    ) async throws -> AsyncThrowingStream<ConverseStreamElement, any Error> {
        do {
            guard model.hasConverseStreamingModality() else {
                throw BedrockServiceError.invalidModality(
                    model,
                    try model.getConverseModality(),
                    "This model does not support converse streaming."
                )
            }
            let modality = try model.getConverseModality()
            let parameters = modality.getConverseParameters()
            try parameters.validate(
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                stopSequences: stopSequences
            )

            logger.trace(
                "Creating ConverseStreamingRequest",
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
            let converseRequest = ConverseStreamingRequest(
                model: model,
                messages: conversation,
                maxTokens: maxTokens,
                temperature: temperature,
                topP: topP,
                stopSequences: stopSequences,
                systemPrompts: systemPrompts,
                tools: tools
            )

            logger.trace("Creating ConverseStreamingInput")
            let input = try converseRequest.getConverseStreamingInput()

            logger.trace(
                "Sending ConverseStreaminInput to BedrockRuntimeClient",
                metadata: [
                    "input.messages.count": "\(String(describing:input.messages!.count))",
                    "input.modelId": "\(String(describing:input.modelId!))",
                ]
            )
            let response: ConverseStreamOutput = try await self.bedrockRuntimeClient.converseStream(input: input)

            logger.trace("Received response", metadata: ["response": "\(response)"])

            guard let sdkStream = response.stream else {
                throw BedrockServiceError.invalidSDKResponse(
                    "The response stream is missing. This error should never happen."
                )
            }

            let reply = ConverseReplyStream(sdkStream)
            return reply.stream


            // at this time, we have a stream. The stream is a message, with multiple content blocks
            // - message start
            // - message content start
            // - message content delta
            // - message content end
            // - message stop
            // - message metadata
            // see https://github.com/awslabs/aws-sdk-swift/blob/2697fb44f607b9c43ad0ce5ca79867d8d6c545c2/Sources/Services/AWSBedrockRuntime/Sources/AWSBedrockRuntime/Models.swift#L3478
            // it will be the responsibility of the user to handle the stream and re-assemble the messages and content
            // TODO: should we expose the SDK ConverseStreamOutput from the SDK ? or wrap it (what's the added value) ?
            // return stream
        } catch {
            try handleCommonError(error, context: "invoking converse stream")
            throw BedrockServiceError.unknownError("\(error)")  // FIXME: handleCommonError will always throw
        }
    }

    /// Use Converse Stream API with the ConverseBuilder
    /// - Parameters:
    ///   - builder: ConverseBuilder object
    /// - Throws: BedrockServiceError.invalidSDKResponse if the response body is missing
    /// - Returns: A stream of ConverseResponseStreaming objects
    public func converse(
        with builder: ConverseRequestBuilder
    ) async throws -> AsyncThrowingStream<ConverseStreamElement, any Error> {
        logger.trace("Conversing and streaming")
        do {
            var history = builder.history
            let userMessage = try builder.getUserMessage()
            history.append(userMessage)
            let streamingResponse: AsyncThrowingStream<ConverseStreamElement, any Error> = try await converse(
                with: builder.model,
                conversation: history,
                maxTokens: builder.maxTokens,
                temperature: builder.temperature,
                topP: builder.topP,
                stopSequences: builder.stopSequences,
                systemPrompts: builder.systemPrompts,
                tools: builder.tools
            )
            return streamingResponse
        } catch {
            logger.trace("Error while conversing", metadata: ["error": "\(error)"])
            throw error
        }
    }
}
