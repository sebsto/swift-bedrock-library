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

import Testing

@testable import BedrockService
@testable import BedrockTypes

// MARK - Streaming converse tekst

extension BedrockServiceTests {

    @Test("Streaming converse with reasoning")
    func streamingConverseReasoning() async throws {

        // First call, with reasoning enabled

        var builder = try ConverseRequestBuilder(with: .claudev3_7_sonnet)
            .withPrompt("What is this?")
            .withReasoning()

        #expect(builder.prompt == "What is this?")
        #expect(builder.enableReasoning == true)
        #expect(builder.maxReasoningTokens == 4096)

        var stream: AsyncThrowingStream<ConverseStreamElement, Error> = try await bedrock.converse(with: builder)

        // Collect all the stream elements
        var streamElements: [ConverseStreamElement] = []
        for try await element in stream {
            streamElements.append(element)
        }

        // Verify the stream elements
        #expect(streamElements.count == 6)

        var message: Message = Message("")
        if case .messageComplete(let msg) = streamElements.last {
            message = msg
        } else {
            Issue.record("Expected message")
        }

        #expect(message.content.count == 1)
        #expect(message.role == .assistant)

        if case .reasoning(let reasoning) = message.content.first {
            #expect(reasoning.reasoning == "reasoning text")
        }
        if case .text(let text) = message.content.last {
            #expect(text == "Hello, your prompt was: What is this?")
        }

        // Second call, still with reasoning enabled

        builder = try ConverseRequestBuilder(from: builder, with: message)
            .withPrompt("Second prompt")

        #expect(builder.prompt == "Second prompt")
        #expect(builder.enableReasoning == true)
        #expect(builder.maxReasoningTokens == 4096)
        #expect(builder.history.count == 2)

        stream = try await bedrock.converse(with: builder)

        // Collect all the stream elements
        streamElements = []
        for try await element in stream {
            streamElements.append(element)
        }

        // Verify the stream elements
        #expect(streamElements.count == 6)

        message = Message("")
        if case .messageComplete(let msg) = streamElements.last {
            message = msg
        } else {
            Issue.record("Expected message")
        }

        #expect(message.content.count == 1)
        #expect(message.role == .assistant)

        if case .reasoning(let reasoning) = message.content.first {
            #expect(reasoning.reasoning == "reasoning text")
        }
        if case .text(let text) = message.content.last {
            #expect(text == "Hello, your prompt was: Second prompt")
        }

        // Third call, without reasoning enabled

        builder = try ConverseRequestBuilder(from: builder, with: message)
            .withPrompt("Third prompt")
            .withReasoning(false)

        #expect(builder.prompt == "Third prompt")
        #expect(builder.enableReasoning == false)
        #expect(builder.maxReasoningTokens == nil)
        #expect(builder.history.count == 4)

        stream = try await bedrock.converse(with: builder)

        // Collect all the stream elements
        streamElements = []
        for try await element in stream {
            streamElements.append(element)
        }

        // Verify the stream elements
        #expect(streamElements.count == 6)

        message = Message("")
        if case .messageComplete(let msg) = streamElements.last {
            message = msg
        } else {
            Issue.record("Expected message")
        }

        #expect(message.content.count == 1)
        #expect(message.role == .assistant)

        if case .reasoning = message.content.first {
            Issue.record("Expected no reasoning text")
        }
        if case .text(let text) = message.content.last {
            #expect(text == "Hello, your prompt was: Third prompt")
        }
    }
}
