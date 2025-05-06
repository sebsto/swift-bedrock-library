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
            let t = Task {
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
                    // when we reach here, the stream is finished or the Task is cancelled
                    // when cancelled, it will throw CancellationError
                    // not really necessary as this seems to be handled by the Stream anyway.
                    try Task.checkCancellation() 
                    
                } catch {
                    // report any error, including cancellation (but cancellation result in silent stream termination for the consumer)
                    // https://forums.swift.org/t/why-does-asyncthrowingstream-silently-finish-without-error-if-cancelled/72777
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = {
                (termination: AsyncThrowingStream<ConverseStreamElement, Error>.Continuation.Termination) -> Void in
                    if case .cancelled = termination {
                        t.cancel()  // Cancel the task when the stream is terminated
                        // print("Stream cancelled")
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

/*

extension AsyncSequence where Element == (BedrockRuntimeClientTypes.ConverseStreamOutput, Error) {
    func asyncMap<T>(_ transform: @escaping (Element) async throws -> T) -> AsyncThrowingMapSequence<Self, T> {
        return AsyncThrowingMapSequence(self, transform: transform)
    }
}

extension AsyncThrowingMapSequence.Iterator
where Base.Element == (BedrockRuntimeClientTypes.ConverseStreamOutput, Error),
    Output == ConverseStreamElement {

    mutating func next() async throws -> Output? {
        guard let element = try await iterator.next() else {
            return nil
        }

        // Otherwise, apply the transform to the element
        return try await transform(element)
    }
}

struct AsyncThrowingMapSequence<Base: AsyncSequence, Output>: AsyncSequence {
    typealias Element = Output
    typealias AsyncIterator = Iterator

    let base: Base
    let transform: (Base.Element) async throws -> Output

    init(_ base: Base, transform: @escaping (Base.Element) async throws -> Output) {
        self.base = base
        self.transform = transform
    }

    struct Iterator: AsyncIteratorProtocol {
        var iterator: Base.AsyncIterator
        let transform: (Base.Element) async throws -> Output

        init(iterator: Base.AsyncIterator, transform: @escaping (Base.Element) async throws -> Output) {
            self.iterator = iterator
            self.transform = transform
        }

        mutating func next() async throws -> Output? {
            guard let element = try await iterator.next() else {
                return nil
            }
            return try await transform(element)
        }
    }

    func makeAsyncIterator() -> Iterator {
        return Iterator(iterator: base.makeAsyncIterator(), transform: transform)
    }
}
*/
