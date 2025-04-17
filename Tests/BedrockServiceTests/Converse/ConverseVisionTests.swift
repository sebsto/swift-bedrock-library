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

// Converse vision

extension BedrockServiceTests {

    @Test("Converse with vision")
    func converseVision() async throws {
        let bytes = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let builder = try ConverseBuilder(model: BedrockModel.nova_lite)
            .withPrompt("What is this?")
            .withImage(format: .jpeg, source: bytes)
        let reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply == "Image received")
    }

    @Test("Converse with vision and inout builder")
    func converseVisionAndInOutBuilder() async throws {
        let bytes = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        var builder = try ConverseBuilder(model: BedrockModel.nova_lite)
            .withPrompt("What is this?")
            .withImage(format: .jpeg, source: bytes)
        #expect(builder.image != nil)
        let reply = try await bedrock.converse(with: &builder)
        #expect(reply.textReply == "Image received")
        #expect(builder.image == nil)
    }

    @Test("Converse with vision")
    func converseVisionUsingImageBlock() async throws {
        let source = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let image = try ImageBlock(format: .jpeg, source: source)
        let builder = try ConverseBuilder(model: BedrockModel.nova_lite)
            .withPrompt("What is this?")
            .withImage(image)
        let reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply == "Image received")
    }

    @Test("Converse with vision with invalid model")
    func converseVisionInvalidModel() async throws {
        let source = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        #expect(throws: BedrockServiceError.self) {
            let _ = try ConverseBuilder(model: BedrockModel.nova_micro)
                .withPrompt("What is this?")
                .withImage(format: .jpeg, source: source)
        }
    }
}
