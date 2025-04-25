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

// To consider: do we want the developer to use ConverseReplyStream or do we simply use it to return the stream? 
// This will determine the visibility
package struct ConverseReplyStream {
    package var stream: AsyncThrowingStream<ConverseStreamElement, Error>

    package init(_ inputStream: AsyncThrowingStream<BedrockRuntimeClientTypes.ConverseStreamOutput, Error>) {

        self.stream = AsyncThrowingStream(ConverseStreamElement.self) { continuation in
            Task { @Sendable in
                var indexes: [Int] = []
                var contentParts: [ContentSegment] = []
                var content: [Content] = []
                do {
                    for try await output in inputStream {
                        switch output {
                        case .contentblockstart(let event):
                            guard let index = event.contentBlockIndex else {
                                throw BedrockServiceError.streamingError("TODO")
                            }
                            indexes.append(index)

                        case .contentblockdelta(let event):
                            guard let index = event.contentBlockIndex else {
                                throw BedrockServiceError.streamingError("TODO")
                            }
                            guard indexes.contains(index) else {
                                throw BedrockServiceError.streamingError("TODO")
                            }
                            guard let delta = event.delta else {
                                throw BedrockServiceError.streamingError("TODO")
                            }
                            let segment = try ContentSegment(index: index, delta: delta)
                            contentParts.append(segment)
                            continuation.yield(.contentSegment(segment))

                        case .contentblockstop(let event):
                            guard let completedIndex = event.contentBlockIndex else {
                                throw BedrockServiceError.streamingError("TODO")
                            }
                            guard indexes.contains(completedIndex) else {
                                throw BedrockServiceError.streamingError("TODO")
                            }
                            var text = ""
                            contentParts.forEach { segment in
                                switch segment {
                                case .text(let index, let textPart):
                                    if index == completedIndex {
                                        text += textPart
                                    }
                                }
                            }
                            if text != "" {
                                let contentBlock: Content = .text(text)
                                content.append(contentBlock)
                                continuation.yield(.contentBlockComplete(completedIndex, contentBlock))
                            }

                        case .messagestop(_):
                            let message = Message(from: .assistant, content: content)
                            continuation.yield(.messageComplete(message))
                            continuation.finish()

                        default:
                            print("Unexpected delta type")  // FIXME
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

public enum ConverseStreamElement: Sendable {
    case contentSegment(ContentSegment)
    case contentBlockComplete(Int, Content)
    case messageComplete(Message)
}

public enum ContentSegment: Sendable {
    case text(Int, String)

    func getIndex() -> Int {
        switch self {
        case .text(let index, _):
            return index
        }
    }

    init(index: Int, delta sdkContentBlockDelta: BedrockRuntimeClientTypes.ContentBlockDelta) throws {
        switch sdkContentBlockDelta {
        case .text(let text):
            self = .text(index, text)
        case .sdkUnknown:
            throw BedrockServiceError.streamingError("TODO")
        default:
            throw BedrockServiceError.streamingError("TODO")
        }
    }
}
