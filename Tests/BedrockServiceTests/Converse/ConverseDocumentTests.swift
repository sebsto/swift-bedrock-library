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

// Converse document

extension BedrockServiceTests {

    @Test("Converse with document")
    func converseDocumentBlock() async throws {
        let source = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let documentBlock = try DocumentBlock(name: "doc", format: .pdf, source: source)
        let builder = try ConverseBuilder(BedrockModel.nova_lite)
            .withPrompt("What is this?")
            .withDocument(documentBlock)
        let reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply == "Document received")
    }

    @Test("Converse with document")
    func converseDocumentParts() async throws {
        let source = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let builder = try ConverseBuilder(BedrockModel.nova_lite)
            .withPrompt("What is this?")
            .withDocument(name: "doc", format: .pdf, source: source)
        let reply = try await bedrock.converse(with: builder)
        #expect(reply.textReply == "Document received")
    }

    @Test("Converse document with invalid model")
    func converseDocumentInvalidModel() async throws {
        let source = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let documentBlock = try DocumentBlock(name: "doc", format: .pdf, source: source)
        #expect(throws: BedrockServiceError.self) {
            let _ = try ConverseBuilder(BedrockModel.nova_micro)
                .withPrompt("What is this?")
                .withDocument(documentBlock)
        }
    }
}
