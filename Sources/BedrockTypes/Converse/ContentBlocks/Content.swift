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

public enum Content: Codable, CustomStringConvertible, Sendable {
    case text(String)
    case image(ImageBlock)
    case toolUse(ToolUseBlock)
    case toolResult(ToolResultBlock)
    case document(DocumentBlock)
    case video(VideoBlock)
    case reasoning(ReasoningBlock)

    // MARK - Initialiser

    public init(from sdkContentBlock: BedrockRuntimeClientTypes.ContentBlock) throws {
        switch sdkContentBlock {
        case .text(let text):
            self = .text(text)
        case .image(let sdkImage):
            self = .image(try ImageBlock(from: sdkImage))
        case .document(let sdkDocumentBlock):
            self = .document(try DocumentBlock(from: sdkDocumentBlock))
        case .tooluse(let sdkToolUseBlock):
            self = .toolUse(try ToolUseBlock(from: sdkToolUseBlock))
        case .toolresult(let sdkToolResultBlock):
            self = .toolResult(try ToolResultBlock(from: sdkToolResultBlock))
        case .video(let sdkVideoBlock):
            self = .video(try VideoBlock(from: sdkVideoBlock))
        case .reasoningcontent(let sdkReasoningBlock):
            self = .reasoning(try ReasoningBlock(from: sdkReasoningBlock))
        default:
            throw BedrockServiceError.notImplemented(
                "ContentBlock \(sdkContentBlock) is not implemented by BedrockService or not implemented by BedrockRuntimeClientTypes in case of `sdkUnknown`"
            )
        }
    }

    public func getSDKContentBlock() throws -> BedrockRuntimeClientTypes.ContentBlock {
        switch self {
        case .text(let text):
            return BedrockRuntimeClientTypes.ContentBlock.text(text)
        case .image(let imageBlock):
            return BedrockRuntimeClientTypes.ContentBlock.image(try imageBlock.getSDKImageBlock())
        case .document(let documentBlock):
            return BedrockRuntimeClientTypes.ContentBlock.document(try documentBlock.getSDKDocumentBlock())
        case .toolResult(let toolResultBlock):
            return BedrockRuntimeClientTypes.ContentBlock.toolresult(try toolResultBlock.getSDKToolResultBlock())
        case .toolUse(let toolUseBlock):
            return BedrockRuntimeClientTypes.ContentBlock.tooluse(try toolUseBlock.getSDKToolUseBlock())
        case .video(let videoBlock):
            return BedrockRuntimeClientTypes.ContentBlock.video(try videoBlock.getSDKVideoBlock())
        case .reasoning(let reasoningBlock):
            return BedrockRuntimeClientTypes.ContentBlock.reasoningcontent(try reasoningBlock.getSDKReasoningBlock())
        }
    }

    // MARK - convenience methods

    /// a description of the Content depending on the case
    public var description: String {
        switch self {
        case .text(let text):
            return "\(text)"
        case .image(let imageBlock):
            return "Image: \(imageBlock.format)"
        case .toolUse(let toolUseBlock):
            return "ToolUse: \(toolUseBlock.id) - \(toolUseBlock.name))"
        case .toolResult(let toolResultBlock):
            return "ToolResult: \(toolResultBlock.id)"
        case .document(let documentBlock):
            return "Document: \(documentBlock.name) - \(documentBlock.format)"
        case .video(let videoBlock):
            return "Video: \(videoBlock.format)"
        case .reasoning(let reasoningBlock):
            return "Reasoning: \(reasoningBlock)"
        }
    }

    /// convenience method to check what is inside the Content
    public func isText() -> Bool {
        switch self {
        case .text:
            return true
        default:
            return false
        }
    }

    /// convenience method to check what is inside the Content
    public func isImage() -> Bool {
        switch self {
        case .image:
            return true
        default:
            return false
        }
    }

    /// convenience method to check what is inside the Content
    public func isToolUse() -> Bool {
        switch self {
        case .toolUse:
            return true
        default:
            return false
        }
    }

    /// convenience method to check what is inside the Content
    public func isToolResult() -> Bool {
        switch self {
        case .toolResult:
            return true
        default:
            return false
        }
    }

    /// convenience method to check what is inside the Content
    public func isDocument() -> Bool {
        switch self {
        case .document:
            return true
        default:
            return false
        }
    }

    /// convenience method to check what is inside the Content
    public func isVideo() -> Bool {
        switch self {
        case .video:
            return true
        default:
            return false
        }
    }

    /// convenience method to check what is inside the Content
    public func isReasoning() -> Bool {
        switch self {
        case .video:
            return true
        default:
            return false
        }
    }
}
