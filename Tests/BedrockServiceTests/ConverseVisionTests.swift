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
        let reply = try await bedrock.converse(
            with: BedrockModel.nova_lite,
            prompt: "What is this?",
            imageFormat: .jpeg,
            imageBytes: bytes
        )
        #expect(reply.textReply == "Image received")
    }

    @Test("Converse with vision")
    func converseVisionUsingImageBlock() async throws {
        let source = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let imageBlock = ImageBlock(format: .jpeg, source: source)
        let reply = try await bedrock.converse(
            with: BedrockModel.nova_lite,
            prompt: "What is this?",
            image: imageBlock
        )
        #expect(reply.textReply == "Image received")
    }

    @Test("Converse with vision with invalid model")
    func converseVisionInvalidModel() async throws {
        let source = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let imageBlock = ImageBlock(format: .jpeg, source: source)
        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.nova_micro,
                prompt: "What is this?",
                image: imageBlock
            )
        }
    }

    @Test("Converse with vision")
    func converseVisionWithoutFormat() async throws {
        let bytes = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.nova_lite,
                prompt: "What is this?",
                imageBytes: bytes
            )
        }
    }

    @Test("Converse with vision")
    func converseVisionWithoutBytes() async throws {
        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.nova_lite,
                prompt: "What is this?",
                imageFormat: .jpeg
            )
        }
    }
}
