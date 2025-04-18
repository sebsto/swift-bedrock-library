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

import BedrockTypes
import Foundation

public struct ConverseBuilder {

    public private(set) var model: BedrockModel
    private var parameters: ConverseParameters

    public private(set) var history: [Message]
    public private(set) var tools: [Tool]?

    public private(set) var prompt: String?
    public private(set) var image: ImageBlock?
    public private(set) var document: DocumentBlock?
    public private(set) var toolResult: ToolResultBlock?

    public private(set) var maxTokens: Int?
    public private(set) var temperature: Double?
    public private(set) var topP: Double?
    public private(set) var stopSequences: [String]?
    public private(set) var systemPrompts: [String]?

    // MARK - Initializers

    public init(_ model: BedrockModel) throws {
        self.model = model
        let modality = try model.getConverseModality()
        self.parameters = modality.getConverseParameters()
        self.history = []
    }

    public init(_ modelId: String) throws {
        guard let model = BedrockModel(rawValue: modelId) else {
            throw BedrockServiceError.notFound("No model with model id \(modelId) found.")
        }
        self = try .init(model)
    }

    // MARK - builder methods

    // MARK - builder methods - history

    public func withHistory(_ history: [Message]) throws -> ConverseBuilder {
        if let lastMessage = history.last {
            guard lastMessage.role == .assistant else {
                throw BedrockServiceError.converseBuilder("Last message in history must be from assistant.")
            }
        }
        if toolResult != nil {
            guard case .toolUse(_) = history.last?.content.last else {
                throw BedrockServiceError.invalidPrompt("Tool result is defined but last message is not tool use.")
            }
        }
        var copy = self
        copy.history = history
        return copy
    }

    // MARK - builder methods - tools

    public func withTools(_ tools: [Tool]) throws -> ConverseBuilder {
        try validateFeature(.toolUse)
        if case .toolUse(let toolUse) = history.last?.content.last {
            guard tools.contains(where: { $0.name == toolUse.name }) else {
                throw BedrockServiceError.converseBuilder(
                    "Cannot set tools if last message in history contains toolUse and no matching tool is found."
                )
            }
        }
        let toolNames = tools.map { $0.name }
        guard Set(toolNames).count == tools.count else {
            throw BedrockServiceError.converseBuilder("Cannot set tools with duplicate names.")
        }
        var copy = self
        copy.tools = tools
        return copy
    }

    public func withTool(_ tool: Tool) throws -> ConverseBuilder {
        try self.withTools([tool])
    }

    public func withTool(name: String, inputSchema: JSON, description: String?) throws -> ConverseBuilder {
        try self.withTools([try Tool(name: name, inputSchema: inputSchema, description: description)])
    }

    // MARK - builder methods - user prompt

    public func withPrompt(_ prompt: String) throws -> ConverseBuilder {
        guard toolResult == nil else {
            throw BedrockServiceError.converseBuilder("Cannot set prompt when tool result is set")
        }
        try parameters.prompt.validateValue(prompt)
        var copy = self
        copy.prompt = prompt
        return copy
    }

    public func withImage(_ image: ImageBlock) throws -> ConverseBuilder {
        try validateFeature(.vision)
        guard toolResult == nil else {
            throw BedrockServiceError.converseBuilder("Cannot set image when tool result is set")
        }
        var copy = self
        copy.image = image
        return copy
    }

    public func withImage(format: ImageBlock.Format, source: String) throws -> ConverseBuilder {
        try self.withImage(try ImageBlock(format: format, source: source))
    }

    public func withDocument(_ document: DocumentBlock) throws -> ConverseBuilder {
        try validateFeature(.document)
        guard toolResult == nil else {
            throw BedrockServiceError.converseBuilder("Cannot set document when tool result is set")
        }
        var copy = self
        copy.document = document
        return copy
    }

    public func withDocument(
        name: String,
        format: DocumentBlock.Format,
        source: String
    ) throws -> ConverseBuilder {
        try self.withDocument(try DocumentBlock(name: name, format: format, source: source))
    }

    public func withToolResult(_ toolResult: ToolResultBlock) throws -> ConverseBuilder {
        guard prompt == nil && image == nil && document == nil else {
            throw BedrockServiceError.converseBuilder("Cannot set tool result when prompt, image, or document is set")
        }
        guard let _ = tools else {
            throw BedrockServiceError.converseBuilder("Cannot set tool result when tools are not set")
        }
        guard let lastMessage = history.last else {
            throw BedrockServiceError.converseBuilder("Cannot set tool result when history is empty")
        }
        guard case .toolUse(let toolUse) = lastMessage.content.last else {
            throw BedrockServiceError.invalidPrompt("Cannot set tool result when last message is not tool use.")
        }
        guard toolUse.id == toolResult.id else {
            throw BedrockServiceError.invalidPrompt("Tool result name does not match tool use name.")
        }
        try validateFeature(.toolUse)
        var copy = self
        copy.toolResult = toolResult
        return copy
    }

    public func withToolResult(
        id: String? = nil,
        content: [ToolResultBlock.Content],
        status: ToolResultBlock.Status? = nil
    ) throws -> ConverseBuilder {
        let id = try id ?? getToolResultId()
        let toolResult = ToolResultBlock(id: id, content: content, status: status)
        return try self.withToolResult(toolResult)
    }

    public func withToolResult(
        _ text: String,
        id: String? = nil,
        status: ToolResultBlock.Status? = nil
    ) throws -> ConverseBuilder {
        let id = try id ?? getToolResultId()
        let toolResult = ToolResultBlock(text, id: id, status: status)
        return try self.withToolResult(toolResult)
    }

    public func withToolResult(
        _ image: ImageBlock,
        id: String? = nil,
        status: ToolResultBlock.Status? = nil
    ) throws -> ConverseBuilder {
        let id = try id ?? getToolResultId()
        let toolResult = ToolResultBlock(image, id: id, status: status)
        return try self.withToolResult(toolResult)
    }

    public func withToolResult(
        _ document: DocumentBlock,
        id: String? = nil,
        status: ToolResultBlock.Status? = nil
    ) throws -> ConverseBuilder {
        let id = try id ?? getToolResultId()
        let toolResult = ToolResultBlock(document, id: id, status: status)
        return try self.withToolResult(toolResult)
    }

    public func withToolResult(
        _ json: JSON,
        id: String? = nil,
        status: ToolResultBlock.Status? = nil
    ) throws -> ConverseBuilder {
        let id = try id ?? getToolResultId()
        let toolResult = ToolResultBlock(json, id: id, status: status)
        return try self.withToolResult(toolResult)
    }

    public func withToolResult(
        _ video: VideoBlock,
        id: String? = nil,
        status: ToolResultBlock.Status? = nil
    ) throws -> ConverseBuilder {
        let id = try id ?? getToolResultId()
        let toolResult = ToolResultBlock(video, id: id, status: status)
        return try self.withToolResult(toolResult)
    }

    public func withToolResult(
        _ data: Data,
        id: String? = nil,
        status: ToolResultBlock.Status? = nil
    ) throws -> ConverseBuilder {
        let id = try id ?? getToolResultId()
        let toolResult = try ToolResultBlock(data, id: id, status: status)
        return try self.withToolResult(toolResult)
    }

    public func withToolResult<C: Codable>(
        _ object: C,
        id: String? = nil,
        status: ToolResultBlock.Status? = nil
    ) throws -> ConverseBuilder {
        let id = try id ?? getToolResultId()
        let toolResult = try ToolResultBlock(object, id: id, status: status)
        return try self.withToolResult(toolResult)
    }

    public func withFailedToolResult(id: String?) throws -> ConverseBuilder {
        let id = try id ?? getToolResultId()
        let toolResult = ToolResultBlock(id: id, content: [], status: .error)
        return try self.withToolResult(toolResult)
    }

    // MARK - builder methods - inference parameters

    public func withMaxTokens(_ maxTokens: Int) throws -> ConverseBuilder {
        var copy = self
        try copy.parameters.maxTokens.validateValue(maxTokens)
        copy.maxTokens = maxTokens
        return copy
    }

    public func withTemperature(_ temperature: Double) throws -> ConverseBuilder {
        var copy = self
        try copy.parameters.temperature.validateValue(temperature)
        copy.temperature = temperature
        return copy
    }

    public func withTopP(_ topP: Double) throws -> ConverseBuilder {
        var copy = self
        try copy.parameters.topP.validateValue(topP)
        copy.topP = topP
        return copy
    }

    public func withStopSequences(_ stopSequences: [String]) throws -> ConverseBuilder {
        var copy = self
        try copy.parameters.stopSequences.validateValue(stopSequences)
        copy.stopSequences = stopSequences
        return copy
    }

    public func withStopSequence(_ stopSequence: String) throws -> ConverseBuilder {
        try self.withStopSequences([stopSequence])
    }

    public func withSystemPrompts(_ systemPrompts: [String]) throws -> ConverseBuilder {
        var copy = self
        copy.stopSequences = stopSequences
        return copy
    }

    public func withSystemPrompt(_ systemPrompt: String) throws -> ConverseBuilder {
        try self.withSystemPrompts([systemPrompt])
    }

    // MARK - public methods

    /// Returns the user Message made up of the user input in the builder
    public func getUserMessage() throws -> Message {
        try parameters.validate(
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            stopSequences: stopSequences
        )
        return Message(from: .user, content: try getContent())
    }

    // MARK - private methods

    private func getToolResultId() throws -> String {
        guard let lastMessage = history.last else {
            throw BedrockServiceError.converseBuilder("Cannot set tool result when history is empty")
        }
        guard case .toolUse(let toolUse) = lastMessage.content.last else {
            throw BedrockServiceError.invalidPrompt("Cannot set tool result when last message is not tool use.")
        }
        return toolUse.id
    }

    private func validateFeature(_ feature: ConverseFeature) throws {
        guard model.hasConverseModality(feature) else {
            throw BedrockServiceError.invalidModality(
                model,
                try model.getConverseModality(),
                "This model does not support converse feature \(feature)."
            )
        }
    }

    private func getContent() throws -> [Content] {
        var content: [Content] = []
        if let prompt {
            content.append(.text(prompt))
        }
        if let image {
            content.append(.image(image))
        }
        if let document {
            content.append(.document(document))
        }
        if let toolResult {
            content.append(.toolResult(toolResult))
        }
        guard !content.isEmpty else {
            throw BedrockServiceError.converseBuilder("No content defined.")
        }
        return content
    }
}
