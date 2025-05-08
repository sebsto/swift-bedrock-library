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
import Foundation

public struct EncryptedReasoning: Codable, Sendable {
    public var reasoning: Data

    public var description: String {
        "Encrypted reasoning: \(reasoning)"
    }

    public init(_ data: Data) {
        self.reasoning = data
    }

    public func getSDKReasoningBlock() -> BedrockRuntimeClientTypes.ReasoningContentBlock {
        .redactedcontent(reasoning)
    }
}

public struct Reasoning: Codable, CustomStringConvertible, Sendable {
    public var signature: String
    public var reasoning: String

    public init(from sdkReasoningText: BedrockRuntimeClientTypes.ReasoningTextBlock) throws {
        guard let signature = sdkReasoningText.signature else {
            throw BedrockServiceError.invalidSDKType("Signature is missing from ReasoningTextBlock")
        }
        guard let text = sdkReasoningText.text else {
            throw BedrockServiceError.invalidSDKType("Text is missing from ReasoningTextBlock")
        }
        self.signature = signature
        self.reasoning = text
    }

    public func getSDKReasoningBlock() -> BedrockRuntimeClientTypes.ReasoningContentBlock {
        .reasoningtext(
            BedrockRuntimeClientTypes.ReasoningTextBlock(signature: signature, text: reasoning)
        )
    }

    public var description: String {
        "Reasoning: \(reasoning) \nSignature: \(signature)"
    }
}

// public enum ReasoningBlock: Codable, CustomStringConvertible, Sendable {
//     case reasoning(ReasoningText)
//     case reasoningEncrypted(ReasoningEncrypted)

//     init(from sdkReasoningBlock: BedrockRuntimeClientTypes.ReasoningContentBlock) throws {
//         switch sdkReasoningBlock {
//         case .reasoningtext(let sdkReasoningText):
//             self = .reasoning(try ReasoningText(from: sdkReasoningText))
//         case .redactedcontent(let data):
//             self = .reasoningEncrypted(ReasoningEncrypted(reasoning: data))
//         default:
//             throw BedrockServiceError.notImplemented(
//                 "ReasoningContentBlock \(sdkReasoningBlock) is not implemented by BedrockService or not implemented by BedrockRuntimeClientTypes in case of `sdkUnknown`"
//             )
//         }
//     }

//     public var description: String {
//         switch self {
//         case .reasoning(let reasoning):
//             return "Reasoning: \(reasoning.reasoning) \nSignature: \(reasoning.signature)"
//         case .reasoningEncrypted(let reasoningEncrypted):
//             return "Encrypted reasoning: \(reasoningEncrypted)"
//         }
//     }

//     public func getSDKReasoningBlock() throws -> BedrockRuntimeClientTypes.ReasoningContentBlock {
//         switch self {
//         case .reasoning(let reasoning):
//             return .reasoningtext(
//                 BedrockRuntimeClientTypes.ReasoningTextBlock(signature: reasoning.signature, text: reasoning.reasoning)
//             )
//         case .reasoningEncrypted(let reasoningEncrypted):
//             return .redactedcontent(reasoningEncrypted.reasoning)
//         }
//     }
// }
