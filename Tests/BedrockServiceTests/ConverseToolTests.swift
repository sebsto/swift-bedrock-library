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

// Converse tools

extension BedrockServiceTests {

    @Test("Request tool usage")
    func converseRequestTool() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let reply = try await bedrock.converse(
            with: BedrockModel.nova_lite,
            prompt: "Use tool",
            tools: [tool]
        )
        #expect(reply.textReply == nil)
        let id: String
        let name: String
        let input: JSON
        if let toolUse = reply.toolUse {
            id = toolUse.id
            name = toolUse.name
            input = toolUse.input
        } else {
            id = ""
            name = ""
            input = JSON(["code": "wrong"])
        }
        #expect(id == "toolId")
        #expect(name == "toolName")
        #expect(input.getValue("code") == "abc")
    }

    @Test("No tool request without tools")
    func converseRequestToolWithoutTools() async throws {
        let reply = try await bedrock.converse(
            with: BedrockModel.nova_lite,
            prompt: "Use tool"
        )
        #expect(reply.textReply != nil)
        #expect(reply.toolUse == nil)
    }

    @Test("Tool result")
    func converseToolResult() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        let history = [Message("Use tool"), Message(toolUse)]

        let reply = try await bedrock.converse(
            with: BedrockModel.nova_lite,
            history: history,
            tools: [tool],
            toolResult: ToolResultBlock("Information from tool", id: id)
        )
        #expect(reply.toolUse == nil)
        #expect(reply.textReply == "Tool result received")
    }

    @Test("Tool result without toolUse")
    func converseToolResultWithoutToolUse() async throws {
        let tool = try Tool(name: "toolName", inputSchema: JSON(["code": "string"]), description: "toolDescription")
        let id = "toolId"
        let history = [Message("Use tool"), Message(from: .assistant, content: [.text("No need for a tool")])]
        await #expect(throws: BedrockServiceError.self) {
            let reply = try await bedrock.converse(
                with: BedrockModel.nova_lite,
                history: history,
                tools: [tool],
                toolResult: ToolResultBlock("Information from tool", id: id)
            )
        }
    }

    @Test("Tool result without tool")
    func converseToolResultWithoutTool() async throws {
        let id = "toolId"
        let toolUse = ToolUseBlock(id: id, name: "toolName", input: JSON(["code": "abc"]))
        let history = [Message("Use tool"), Message(from: .assistant, content: [.text("No need for a tool")])]
        await #expect(throws: BedrockServiceError.self) {
            let reply = try await bedrock.converse(
                with: BedrockModel.nova_lite,
                history: history,
                toolResult: ToolResultBlock("Information from tool", id: id)
            )
        }
    }
}
