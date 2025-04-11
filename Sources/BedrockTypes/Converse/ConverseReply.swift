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

public struct ConverseReply {
    let history: [Message]
    let textReply: String?
    let toolUse: ToolUseBlock?
    let imageBlock: ImageBlock?
    let videoBlock: VideoBlock?
    // let reasoningBlock: ReasoningBlock?

    // MARK: Initializers

    public init(_ history: [Message]) throws {
        guard let lastMessage = history.last else {
            throw BedrockServiceError.invalidConverseReply("The provided history is not allowed to be empty.")
        }
        guard lastMessage.role == .assistant else {
            throw BedrockServiceError.invalidConverseReply("The last message in the history is not from the assistant.")
        }
        self.history = history
        self.textReply = try? ConverseReply.getTextReply(lastMessage)
        self.toolUse = try? ConverseReply.getToolUse(lastMessage)
        self.imageBlock = try? ConverseReply.getImageBlock(lastMessage)
        self.videoBlock = try? ConverseReply.getVideoBlock(lastMessage)
    }

    // MARK: Private functions

    static private func getTextReply(_ reply: Message) throws -> String {
        for content in reply.content {
            if case .text(let text) = content {
                return text
            }
        }
        throw BedrockServiceError.invalidConverseReply("No text block found in last message.")
    }

    static private func getToolUse(_ reply: Message) throws -> ToolUseBlock {
        for content in reply.content {
            if case .toolUse(let block) = content {
                return block
            }
        }
        throw BedrockServiceError.invalidConverseReply("No ToolUse block found in last message.")
    }

    static private func getImageBlock(_ reply: Message) throws -> ImageBlock {
        for content in reply.content {
            if case .image(let block) = content {
                return block
            }
        }
        throw BedrockServiceError.invalidConverseReply("No Image block found in last message.")
    }

    static private func getVideoBlock(_ reply: Message) throws -> VideoBlock {
        for content in reply.content {
            if case .video(let block) = content {
                return block
            }
        }
        throw BedrockServiceError.invalidConverseReply("No Video block found in last message.")
    }

    // MARK: Public functions

    func hasTextReply() -> Bool { textReply != nil }
    func hasToolUse() -> Bool { toolUse != nil }
    func hasImage() -> Bool { imageBlock != nil }
    func hasVideo() -> Bool { videoBlock != nil }

    /// Returns the latest text reply or throws if the latest message does not contain a text reply
    func getTextReply(_ reply: Message) throws -> String {
        guard let textReply else {
            throw BedrockServiceError.invalidConverseReply("No text block found in last message.")
        }
        return textReply
    }

    /// Returns the latest tool use request or throws if the latest message does not contain a tool use request
    func getToolUse(_ reply: Message) throws -> ToolUseBlock {
        guard let toolUse else {
            throw BedrockServiceError.invalidConverseReply("No ToolUse block found in last message.")
        }
        return toolUse
    }

    /// Returns the latest image block or throws if the latest message does not contain an image block
    func getImageBlock(_ reply: Message) throws -> ImageBlock {
        guard let imageBlock else {
            throw BedrockServiceError.invalidConverseReply("No Image block found in last message.")
        }
        return imageBlock
    }

    /// Returns the latest video block or throws if the latest message does not contain a video block
    func getVideoBlock(_ reply: Message) throws -> VideoBlock {
        guard let videoBlock else {
            throw BedrockServiceError.invalidConverseReply("No Video block found in last message.")
        }
        return videoBlock
    }
}
