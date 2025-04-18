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
        let builder = try ConverseBuilder(BedrockModel.nova_lite)
            .withPrompt("What is this?")
            .withImage(format: .jpeg, source: bytes)
        let reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply == "Image received")
    }

    @Test("Converse with vision")
    func converseVisionUsingImageBlock() async throws {
        let source = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let image = try ImageBlock(format: .jpeg, source: source)
        let builder = try ConverseBuilder(BedrockModel.nova_lite)
            .withPrompt("What is this?")
            .withImage(image)
        let reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply == "Image received")
    }

    @Test("Converse with vision and inout builder")
    func converseVisionAndInOutBuilder() async throws {
        let bytes = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        var builder = try ConverseBuilder(BedrockModel.nova_lite)
            .withPrompt("What is this?")
            .withImage(format: .jpeg, source: bytes)

        #expect(builder.image != nil)
        #expect(builder.image?.format == .jpeg)
        #expect(builder.image?.source == bytes)
        #expect(builder.prompt == "What is this?")

        var reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply == "Image received")

        builder = try ConverseBuilder(from: builder, with: reply)
            .withPrompt("Some prompt")

        #expect(builder.image == nil)
        #expect(builder.prompt != nil)
        #expect(builder.prompt! == "Some prompt")
        #expect(builder.toolResult == nil)
        #expect(builder.history.count == 2)

        reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply != nil)
        #expect(reply.textReply! == "Your prompt was: Some prompt")
    }

    @Test("Converse with vision with invalid model")
    func converseVisionInvalidModel() async throws {
        let source = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        #expect(throws: BedrockServiceError.self) {
            let _ = try ConverseBuilder(BedrockModel.nova_micro)
                .withPrompt("What is this?")
                .withImage(format: .jpeg, source: source)
        }
    }

    @Test("Converse with vision and document and inout builder")
    func converseVisionAndDocumentAndInOutBuilder() async throws {
        let docSource = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let imageBytes = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        var builder = try ConverseBuilder(BedrockModel.nova_lite)
            .withPrompt("What is this?")
            .withImage(format: .jpeg, source: imageBytes)
            .withDocument(name: "doc", format: .pdf, source: docSource)

        #expect(builder.image != nil)
        #expect(builder.image?.format == .jpeg)
        #expect(builder.image?.source == imageBytes)
        #expect(builder.document != nil)
        #expect(builder.document?.name == "doc")
        #expect(builder.document?.format == .pdf)
        #expect(builder.document?.source == docSource)
        #expect(builder.prompt == "What is this?")

        var reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply == "Document received")

        builder = try ConverseBuilder(from: builder, with: reply)
            .withPrompt("Some prompt")

        #expect(builder.image == nil)
        #expect(builder.document == nil)
        #expect(builder.prompt != nil)
        #expect(builder.prompt! == "Some prompt")
        #expect(builder.toolResult == nil)
        #expect(builder.history.count == 2)

        reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply != nil)
        #expect(reply.textReply! == "Your prompt was: Some prompt")
    }
}
