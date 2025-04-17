import BedrockTypes

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

    public init(model: BedrockModel, history: [Message] = []) throws {
        self.model = model
        let modality = try model.getConverseModality()
        self.parameters = modality.getConverseParameters()
        if let lastMessage = history.last {
            guard lastMessage.role == .user else {
                throw BedrockServiceError.converseBuilder("Last message in history must be from user.")
            }
        }
        if toolResult != nil {
            guard case .toolUse(_) = history.last?.content.last else {
                throw BedrockServiceError.invalidPrompt("Tool result is defined but last message is not tool use.")
            }
        }
        self.history = history
    }

    // MARK - mutating methods

    // MARK - mutating methods - model

    public mutating func withModel(_ model: BedrockModel) throws -> ConverseBuilder {
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
        self.parameters = parameters
        self.model = model
        return self
    }

    public mutating func withModel(_ modelId: String) throws -> ConverseBuilder {
        guard let model = BedrockModel(rawValue: modelId) else {
            throw BedrockServiceError.notFound("No model with model id \(modelId) found.")
        }
        return try self.withModel(model)
    }

    // MARK - mutating methods - history

    public mutating func withHistory(_ history: [Message]) throws -> ConverseBuilder {
        if let lastMessage = history.last {
            guard lastMessage.role == .user else {
                throw BedrockServiceError.converseBuilder("Last message in history must be from user.")
            }
        }
        if toolResult != nil {
            guard case .toolUse(_) = history.last?.content.last else {
                throw BedrockServiceError.invalidPrompt("Tool result is defined but last message is not tool use.")
            }
        }
        self.history = history
        return self
    }

    // MARK - mutating methods - tools

    public mutating func withTools(_ tools: [Tool]) throws -> ConverseBuilder {
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
        try validateFeature(.toolUse)
        self.tools = tools
        return self
    }

    public mutating func addTool(_ tool: Tool) throws -> ConverseBuilder {
        if var tools {
            if tools.contains(where: { $0.name == tool.name }) {
                throw BedrockServiceError.converseBuilder("Cannot add tool with duplicate name.")
            }
            tools.append(tool)
            self.tools = tools
        } else {
            self.tools = [tool]
        }
        try validateFeature(.toolUse)
        return self
    }

    public mutating func removeTool(_ name: String) throws -> ConverseBuilder {
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
        try validateFeature(.toolUse)
        return self
    }

    public mutating func removeTool(_ tool: Tool) throws -> ConverseBuilder {
        return try removeTool(tool.name)
    }

    // MARK - mutating methods - user prompt

    public mutating func withPrompt(_ prompt: String) throws -> ConverseBuilder {
        guard toolResult == nil else {
            throw BedrockServiceError.converseBuilder("Cannot set prompt when tool result is set")
        }
        try parameters.prompt.validateValue(prompt)
        self.prompt = prompt
        return self
    }

    public mutating func withImage(_ image: ImageBlock) throws -> ConverseBuilder {
        guard toolResult == nil else {
            throw BedrockServiceError.converseBuilder("Cannot set image when tool result is set")
        }
        try validateFeature(.vision)
        self.image = image
        return self
    }

    public mutating func withImage(format: ImageBlock.Format, source: String) throws -> ConverseBuilder {
        try self.withImage(try ImageBlock(format: format, source: source))
    }

    public mutating func withDocument(_ document: DocumentBlock) throws -> ConverseBuilder {
        guard toolResult == nil else {
            throw BedrockServiceError.converseBuilder("Cannot set document when tool result is set")
        }
        try validateFeature(.document)
        self.document = document
        return self
    }

    public mutating func withDocument(
        name: String,
        format: DocumentBlock.Format,
        source: String
    ) throws -> ConverseBuilder {
        try self.withDocument(try DocumentBlock(name: name, format: format, source: source))
    }

    public mutating func withToolResult(_ toolResult: ToolResultBlock) throws -> ConverseBuilder {
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
        return self
    }

    public mutating func withToolResult(
        id: String?,
        content: [ToolResultBlock.Content],
        status: ToolResultBlock.Status?
    ) throws -> ConverseBuilder {
        var id = id
        if id == nil {
            guard let lastMessage = history.last else {
                throw BedrockServiceError.converseBuilder("Cannot set tool result when history is empty")
            }
            guard case .toolUse(let toolUse) = lastMessage.content.last else {
                throw BedrockServiceError.invalidPrompt("Cannot set tool result when last message is not tool use.")
            }
            id = toolUse.id
        }
        let toolResult = ToolResultBlock(id: id!, content: content, status: status)
        return try self.withToolResult(toolResult)
    }

    public mutating func withFailedToolResult(id: String?) throws -> ConverseBuilder {
        var id = id
        if id == nil {
            guard let lastMessage = history.last else {
                throw BedrockServiceError.converseBuilder("Cannot set tool result when history is empty")
            }
            guard case .toolUse(let toolUse) = lastMessage.content.last else {
                throw BedrockServiceError.invalidPrompt("Cannot set tool result when last message is not tool use.")
            }
            id = toolUse.id
        }
        let toolResult = ToolResultBlock(id: id!, content: [], status: .error)
        return try self.withToolResult(toolResult)
    }

    // MARK - mutating methods - inference parameters

    public mutating func withMaxTokens(_ maxTokens: Int) throws -> ConverseBuilder {
        try parameters.maxTokens.validateValue(maxTokens)
        self.maxTokens = maxTokens
        return self
    }

    public mutating func withTemperature(_ temperature: Double) throws -> ConverseBuilder {
        try parameters.temperature.validateValue(temperature)
        self.temperature = temperature
        return self
    }

    public mutating func withTopP(_ topP: Double) throws -> ConverseBuilder {
        try parameters.topP.validateValue(topP)
        self.topP = topP
        return self
    }

    public mutating func withStopSequences(_ stopSequences: [String]) throws -> ConverseBuilder {
        try parameters.stopSequences.validateValue(stopSequences)
        self.stopSequences = stopSequences
        return self
    }

    public mutating func withSystemPrompts(_ systemPrompts: [String]) throws -> ConverseBuilder {
        self.systemPrompts = systemPrompts
        return self
    }

    // MARK - public methods

    /// Returns the user Message made up of the user input in the builder
    public func getUserMessage() throws -> Message {
        Message(from: .user, content: try getContent())
    }

    /// Returns a ConverseBuilder object with an updated history and all the user input emptied out.
    public func resetBuilder(_ history: [Message]) throws -> ConverseBuilder {
        var builder = try ConverseBuilder(model: model, history: history)
        if let tools {
            builder.tools = tools
        }
        if let systemPrompts {
            builder.systemPrompts = systemPrompts
        }
        if let maxTokens {
            builder.maxTokens = maxTokens
        }
        if let temperature {
            builder.temperature = temperature
        }
        if let topP {
            builder.topP = topP
        }
        if let stopSequences {
            builder.stopSequences = stopSequences
        }
        if let tools {
            builder.tools = tools
        }
        return builder
    }

        // MARK - private methods

    private func validateFeature(_ feature: ConverseFeature) throws {
        guard model.hasConverseModality(.document) else {
            throw BedrockServiceError.invalidModality(
                model,
                try model.getConverseModality(),
                "This model does not support converse document."
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
