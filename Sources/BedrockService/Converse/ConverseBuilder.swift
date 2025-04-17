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

    public init(model: BedrockModel) throws {
        self.model = model
        let modality = try model.getConverseModality()
        self.parameters = modality.getConverseParameters()
        self.history = []
    }

    // MARK - builder methods

    // MARK - builder methods - model

    public func withModel(_ model: BedrockModel) throws -> ConverseBuilder {
        var copy = self
        try copy.setModel(model)
        return copy
    }

    public func withModel(_ modelId: String) throws -> ConverseBuilder {
        guard let model = BedrockModel(rawValue: modelId) else {
            throw BedrockServiceError.notFound("No model with model id \(modelId) found.")
        }
        return try self.withModel(model)
    }

    // MARK - builder methods - history

    public func withHistory(_ history: [Message]) throws -> ConverseBuilder {
        var copy = self
        try copy.setHistory(history)
        return copy
    }

    // MARK - builder methods - tools

    public func withTools(_ tools: [Tool]) throws -> ConverseBuilder {
        var copy = self
        try copy.setTools(tools)
        return copy
    }

    public func withTool(_ tool: Tool) throws -> ConverseBuilder {
        try self.withTools([tool])
    }

    public func withTool(name: String, inputSchema: JSON, description: String?) throws -> ConverseBuilder {
        try self.withTools([try Tool(name: name, inputSchema: inputSchema, description: description)])
    }

    public func addTool(_ tool: Tool) throws -> ConverseBuilder {
        var copy = self
        try copy.setAdditionalTool(tool)
        return copy
    }

    public func removeTool(_ name: String) throws -> ConverseBuilder {
        var copy = self
        try copy.deleteTool(name)
        return copy
    }

    public func removeTool(_ tool: Tool) throws -> ConverseBuilder {
        try removeTool(tool.name)
    }

    // MARK - builder methods - user prompt

    public func withPrompt(_ prompt: String) throws -> ConverseBuilder {
        var copy = self
        try copy.setPrompt(prompt)
        return copy
    }

    public func withImage(_ image: ImageBlock) throws -> ConverseBuilder {
        var copy = self
        try copy.setImage(image)
        return copy
    }

    public func withImage(format: ImageBlock.Format, source: String) throws -> ConverseBuilder {
        try self.withImage(try ImageBlock(format: format, source: source))
    }

    public func withDocument(_ document: DocumentBlock) throws -> ConverseBuilder {
        var copy = self
        try copy.setDocument(document)
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
        var copy = self
        try copy.setToolResult(toolResult)
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
        try copy.setMaxTokens(maxTokens)
        return copy
    }

    public func withTemperature(_ temperature: Double) throws -> ConverseBuilder {
        var copy = self
        try copy.setTemperature(temperature)
        return copy
    }

    public func withTopP(_ topP: Double) throws -> ConverseBuilder {
        var copy = self
        try copy.setTopP(topP)
        return copy
    }

    public func withStopSequences(_ stopSequences: [String]) throws -> ConverseBuilder {
        var copy = self
        try copy.setStopSequences(stopSequences)
        return copy
    }

    public func withStopSequence(_ stopSequence: String) throws -> ConverseBuilder {
        var copy = self
        try copy.setStopSequences([stopSequence])
        return copy
    }

    public func withSystemPrompts(_ systemPrompts: [String]) throws -> ConverseBuilder {
        var copy = self
        try copy.setSystemPrompts(systemPrompts)
        return copy
    }

    public func withSystemPrompt(_ systemPrompt: String) throws -> ConverseBuilder {
        var copy = self
        try copy.setSystemPrompts([systemPrompt])
        return copy
    }

    // MARK - public methods

    /// Returns the user Message made up of the user input in the builder
    public func getUserMessage() throws -> Message {
        Message(from: .user, content: try getContent())
    }

    /// Returns a ConverseBuilder object with an updated history and all the user input emptied out.
    public mutating func resetBuilder(_ history: [Message]) throws {
        prompt = nil
        image = nil
        document = nil
        toolResult = nil
        try setHistory(history)
    }

    // MARK - private methods

    // Mutating methods

    public mutating func setModel(_ model: BedrockModel) throws {
        let modality = try model.getConverseModality()
        let parameters = modality.getConverseParameters()
        if tools != nil || toolResult != nil {
            try validateFeature(.toolUse)
        }
        if image != nil {
            try validateFeature(.vision)
        }
        if document != nil {
            try validateFeature(.document)
        }
        try parameters.validate(
            prompt: prompt,
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            stopSequences: stopSequences
        )
        self.model = model
        self.parameters = parameters
    }

    public mutating func setHistory(_ history: [Message]) throws {
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
        self.history = history
    }

    public mutating func setTools(_ tools: [Tool]) throws {
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
        self.tools = tools
    }

    public mutating func setAdditionalTool(_ tool: Tool) throws {
        try validateFeature(.toolUse)
        if var tools {
            if tools.contains(where: { $0.name == tool.name }) {
                throw BedrockServiceError.converseBuilder("Cannot add tool with duplicate name.")
            }
            tools.append(tool)
            self.tools = tools
        } else {
            self.tools = [tool]
        }
    }

    public mutating func deleteTool(_ name: String) throws {
        try validateFeature(.toolUse)
        guard var tools else {
            throw BedrockServiceError.converseBuilder("Cannot remove tool if tools is not set.")
        }
        guard tools.last != nil else {
            throw BedrockServiceError.converseBuilder("Cannot remove tool if tools is empty.")
        }
        guard tools.contains(where: { $0.name == name }) == true else {
            throw BedrockServiceError.notFound("No tool with name \(name) found.")
        }
        if case .toolUse(let toolUse) = history.last?.content.last {
            guard name != toolUse.name else {
                throw BedrockServiceError.converseBuilder(
                    "Cannot remove tool if last message in history contains toolUse with a matching name."
                )
            }
        }
        tools.removeAll(where: { $0.name == name })
        self.tools = tools
    }

    public mutating func setPrompt(_ prompt: String) throws {
        guard toolResult == nil else {
            throw BedrockServiceError.converseBuilder("Cannot set prompt when tool result is set")
        }
        try parameters.prompt.validateValue(prompt)
        self.prompt = prompt
    }

    public mutating func setImage(_ image: ImageBlock) throws {
        try validateFeature(.vision)
        guard toolResult == nil else {
            throw BedrockServiceError.converseBuilder("Cannot set image when tool result is set")
        }
        self.image = image
    }

    public mutating func setDocument(_ document: DocumentBlock) throws {
        try validateFeature(.document)
        guard toolResult == nil else {
            throw BedrockServiceError.converseBuilder("Cannot set document when tool result is set")
        }
        self.document = document
    }

    public mutating func setToolResult(_ toolResult: ToolResultBlock) throws {
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
        self.toolResult = toolResult
    }

    public mutating func setMaxTokens(_ maxTokens: Int) throws {
        try parameters.maxTokens.validateValue(maxTokens)
        self.maxTokens = maxTokens
    }

    public mutating func setTemperature(_ temperature: Double) throws {
        try parameters.temperature.validateValue(temperature)
        self.temperature = temperature
    }

    public mutating func setSystemPrompts(_ systemPrompts: [String]) throws {
        self.systemPrompts = systemPrompts
    }

    public mutating func setStopSequences(_ stopSequences: [String]) throws {
        try parameters.stopSequences.validateValue(stopSequences)
        self.stopSequences = stopSequences
    }

    public mutating func setTopP(_ topP: Double) throws {
        try parameters.topP.validateValue(topP)
        self.topP = topP
    }

    // Varia

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
