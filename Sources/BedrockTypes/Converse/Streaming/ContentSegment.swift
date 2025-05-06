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

public enum ContentSegment: Sendable {
    case text(Int, String)
    // case reasoning(Int, String)
    case toolUse(Int, ToolUseBlock)

    public var index: Int {
        switch self {
        case .text(let index, _):
            return index
        case .toolUse(let index, _):
            return index
        // case .reasoning(let index, _):
        //     return index
        }
    }

    // MARK - Init

    package init(
        index: Int,
        sdkContentBlockDelta: BedrockRuntimeClientTypes.ContentBlockDelta,
        toolUseStarts: [ToolUseStart]
    ) throws {
        switch sdkContentBlockDelta {
        case .text(let text):
            self = .text(index, text)
        case .tooluse(let toolUseBlockDelta):
            guard let input = toolUseBlockDelta.input else {
                throw BedrockServiceError.streamingError("TODO")
            }
            guard let toolUseStart: ToolUseStart = toolUseStarts.first(where: { $0.index == index })
            else {
                throw BedrockServiceError.streamingError("TODO")
            }
            self = .toolUse(
                index,
                ToolUseBlock(
                    id: toolUseStart.toolUseId,
                    name: toolUseStart.name,
                    input: JSON(input)
                )
            )
        // case .reasoningcontent(let sdkReasoningBlock):
        //     ...
        default:
            throw BedrockServiceError.streamingError("TODO")
        }
    }

    // MARK - convenience

    public func hasToolUse() -> Bool {
        switch self {
        case .toolUse:
            return true
        default:
            return false
        }
    }

    public func hasText() -> Bool {
        switch self {
        case .text:
            return true
        default:
            return false
        }
    }
}

extension Content {
    static func getFromSegements(with index: Int, from segments: [ContentSegment]) throws -> Content {
        var text = ""
        var toolUse: ToolUseBlock? = nil
        try segments.forEach { segment in
            if segment.index == index {
                switch segment {
                case .text(_, let textPart):
                    guard toolUse == nil else {
                        throw BedrockServiceError.streamingError("TODO")
                    }
                    text += textPart
                case .toolUse(_, let toolUseBlock):
                    guard text == "" else {
                        throw BedrockServiceError.streamingError("TODO")
                    }
                    toolUse = toolUseBlock
                    break
                }
            }
        }
        if text != "" {
            return .text(text)
        } else if let toolUse {
            return .toolUse(toolUse)
        } else {
            throw BedrockServiceError.streamingError("No content found in ContentSegments to create Content")
        }
    }
}

package struct ToolUseStart: Sendable {
    var index: Int
    var name: String
    var toolUseId: String

    init(index: Int, sdkToolUseStart: BedrockRuntimeClientTypes.ToolUseBlockStart) throws {
        guard let name = sdkToolUseStart.name else {
            throw BedrockServiceError.streamingError("TODO")
        }
        guard let toolUseId = sdkToolUseStart.toolUseId else {
            throw BedrockServiceError.streamingError("TODO")
        }
        self.index = index
        self.name = name
        self.toolUseId = toolUseId
    }
}
