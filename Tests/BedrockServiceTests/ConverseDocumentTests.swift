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

    // @Test("Converse with document")
    // func converseDocument() async throws {
    //     let bytes = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
    //     let reply = try await bedrock.converse(
    //         with: BedrockModel.nova_lite,
    //         prompt: "What is this?",
    //         documentName: "doc",
    //         documentFormat: .jpeg,
    //         documentBytes: bytes
    //     )
    //     #expect(reply.textReply == "Image received")
    // }

    // @Test("Converse with document")
    // func converseDocumentUsingDocumentBlock() async throws {
    //     let source = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
    //     let documentBlock = DocumentBlock(name: "doc", format: .pdf, source: source)
    //     let reply = try await bedrock.converse(
    //         with: BedrockModel.nova_lite,
    //         prompt: "What is this?",
    //         document: documentBlock
    //     )
    //     #expect(reply.textReply == "Image received")
    // }
}
