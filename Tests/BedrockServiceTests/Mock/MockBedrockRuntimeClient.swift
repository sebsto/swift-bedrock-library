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
import AWSClientRuntime
import AWSSDKIdentity
import BedrockService
import BedrockTypes
import Foundation

public struct MockBedrockRuntimeClient: BedrockRuntimeClientProtocol {
    public init() {}

    // MARK: converse
    public func converse(input: ConverseInput) async throws -> ConverseOutput {
        guard let messages = input.messages,
            let content = messages.last?.content?.last
        else {
            throw AWSBedrockRuntime.ValidationException(message: "Missing required message content")
        }
        var message: BedrockRuntimeClientTypes.Message
        print("start switch")
        switch content {
        case .text(let prompt):
            if prompt == "Use tool", let _ = input.toolConfig?.tools {
                let toolInputJson = JSON(["code": "abc"])
                let toolInput = try? toolInputJson.toDocument()
                let message = BedrockRuntimeClientTypes.Message(
                    content: [
                        .tooluse(
                            BedrockRuntimeClientTypes.ToolUseBlock(
                                input: toolInput,
                                name: "toolName",
                                toolUseId: "toolId"
                            )
                        )
                    ],
                    role: .assistant
                )
                return ConverseOutput(output: .message(message))
            }
            message = BedrockRuntimeClientTypes.Message(
                content: [.text("Your prompt was: \(prompt)")],
                role: .assistant
            )
        case .toolresult(_):
            message = BedrockRuntimeClientTypes.Message(
                content: [.text("Tool result received")],
                role: .assistant
            )
        case .image(_):
            message = BedrockRuntimeClientTypes.Message(
                content: [.text("Image received")],
                role: .assistant
            )
        case .document(_):
            message = BedrockRuntimeClientTypes.Message(
                content: [.text("Document received")],
                role: .assistant
            )
        default:
            throw AWSBedrockRuntime.ValidationException(
                message: "Malformed input request, please reformat your input and try again."
            )
        }
        return ConverseOutput(output: .message(message))
    }

    // MARK: invokeModel

    public func invokeModel(input: InvokeModelInput) async throws -> InvokeModelOutput {
        guard let modelId = input.modelId else {
            throw AWSBedrockRuntime.ValidationException(
                message: "Malformed input request, please reformat your input and try again."
            )
        }
        guard let inputBody = input.body else {
            throw AWSBedrockRuntime.ValidationException(
                message: "Malformed input request, please reformat your input and try again."
            )
        }
        let model: BedrockModel = BedrockModel(rawValue: modelId)!

        switch model.modality.getName() {
        case "Amazon Image Generation":
            return InvokeModelOutput(body: try getImageGeneration(body: inputBody))
        case "Nova Text Generation":
            return InvokeModelOutput(body: try invokeNovaModel(body: inputBody))
        case "Titan Text Generation":
            return InvokeModelOutput(body: try invokeTitanModel(body: inputBody))
        case "Anthropic Text Generation":
            return InvokeModelOutput(body: try invokeAnthropicModel(body: inputBody))
        default:
            throw AWSBedrockRuntime.ValidationException(
                message: "Malformed input request, please reformat your input and try again."
            )
        }
    }

    private func getImageGeneration(body: Data) throws -> Data {
        guard
            let json: [String: Any] = try? JSONSerialization.jsonObject(
                with: body,
                options: []
            )
                as? [String: Any],
            let imageGenerationConfig = json["imageGenerationConfig"] as? [String: Any]
        else {
            throw AWSBedrockRuntime.ValidationException(
                message: "Malformed input request, please reformat your input and try again."
            )
        }
        let nrOfImages = imageGenerationConfig["numberOfImages"] as? Int ?? 1
        let mockBase64Image =
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII="
        let imageArray = Array(repeating: "\"\(mockBase64Image)\"", count: nrOfImages)
        return """
            {
                "images": [
                    \(imageArray.joined(separator: ",\n                "))
                ]
            }
            """.data(using: .utf8)!
    }

    private func invokeNovaModel(body: Data) throws -> Data? {
        guard
            let json: [String: Any] = try? JSONSerialization.jsonObject(
                with: body,
                options: []
            )
                as? [String: Any]
        else {
            throw AWSBedrockRuntime.ValidationException(
                message: "Malformed input request, please reformat your input and try again."
            )
        }
        if let messages = json["messages"] as? [[String: Any]],
            let firstMessage = messages.first,
            let content = firstMessage["content"] as? [[String: Any]],
            let firstContent = content.first,
            let inputText = firstContent["text"] as? String
        {
            return """
                {
                    "output":{
                        "message":{
                            "content":[
                                {"text":"This is the textcompletion for: \(inputText)"}
                            ],
                            "role":"assistant"
                        }},
                    "stopReason":"end_turn",
                    "usage":{
                        "inputTokens":5,
                        "outputTokens":244,
                        "totalTokens":249,
                        "cacheReadInputTokenCount":0,
                        "cacheWriteInputTokenCount":0
                    }
                }
                """.data(using: .utf8)!
        } else {
            throw AWSBedrockRuntime.ValidationException(
                message: "Malformed input request, please reformat your input and try again."
            )
        }
    }

    private func invokeTitanModel(body: Data) throws -> Data? {
        guard
            let json: [String: Any] = try? JSONSerialization.jsonObject(
                with: body,
                options: []
            )
                as? [String: Any]
        else {
            throw AWSBedrockRuntime.ValidationException(
                message: "Hier is het)"
                    // message: "Malformed input request, please reformat your input and try again."
            )
        }
        if let inputText = json["inputText"] as? String {
            return """
                {
                    "inputTextTokenCount":5,
                    "results":[
                        {
                            "tokenCount":105,
                            "outputText":"This is the textcompletion for: \(inputText)",
                            "completionReason":"FINISH"
                            }
                    ]
                }
                """.data(using: .utf8)!
        } else {
            throw AWSBedrockRuntime.ValidationException(
                message: "Malformed input request, please reformat your input and try again."
            )
        }
    }

    private func invokeAnthropicModel(body: Data) throws -> Data? {
        guard
            let json: [String: Any] = try? JSONSerialization.jsonObject(
                with: body,
                options: []
            )
                as? [String: Any]
        else {
            throw AWSBedrockRuntime.ValidationException(
                message: "Malformed input request, please reformat your input and try again."
            )
        }
        if let messages = json["messages"] as? [[String: Any]],
            let firstMessage = messages.first,
            let content = firstMessage["content"] as? [[String: Any]],
            let firstContent = content.first,
            let inputText = firstContent["text"] as? String
        {
            return """
                {
                    "id":"msg_bdrk_0146cw8Wd6Dn8WZiQWeF6TEj",
                    "type":"message",
                    "role":"assistant",
                    "model":"claude-3-haiku-20240307",
                    "content":[
                        {
                            "type":"text",
                            "text":"This is the textcompletion for: \(inputText)"
                        }],
                    "stop_reason":"max_tokens",
                    "stop_sequence":null,
                    "usage":{
                        "input_tokens":12,
                        "output_tokens":100}
                }
                """.data(using: .utf8)!
        } else {
            throw AWSBedrockRuntime.ValidationException(
                message: "Malformed input request, please reformat your input and try again."
            )
        }
    }
}
