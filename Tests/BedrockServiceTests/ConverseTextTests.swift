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

// Converse text

extension BedrockServiceTests {

    // Prompt
    @Test(
        "Continue conversation using a valid prompt",
        arguments: NovaTestConstants.TextGeneration.validPrompts
    )
    func converseWithValidPrompt(prompt: String) async throws {
        let (output, _) = try await bedrock.converse(
            with: BedrockModel.nova_micro,
            prompt: prompt
        )
        #expect(output == "Your prompt was: \(prompt)")
    }

    @Test(
        "Continue conversation variation using an invalid prompt",
        arguments: NovaTestConstants.TextGeneration.invalidPrompts
    )
    func converseWithInvalidPrompt(prompt: String) async throws {
        await #expect(throws: BedrockServiceError.self) {
            let _ = try await bedrock.converse(
                with: BedrockModel.nova_micro,
                prompt: prompt
            )
        }
    }

    // Temperature
    @Test(
        "Continue conversation using a valid temperature",
        arguments: NovaTestConstants.TextGeneration.validTemperature
    )
    func converseWithValidTemperature(temperature: Double) async throws {
        let prompt = "This is a test"
        let (output, _) = try await bedrock.converse(
            with: BedrockModel.nova_micro,
            prompt: prompt,
            temperature: temperature
        )
        #expect(output == "Your prompt was: \(prompt)")
    }

    @Test(
        "Continue conversation variation using an invalid temperature",
        arguments: NovaTestConstants.TextGeneration.invalidTemperature
    )
    func converseWithInvalidTemperature(temperature: Double) async throws {
        await #expect(throws: BedrockServiceError.self) {
            let prompt = "This is a test"
            let _ = try await bedrock.converse(
                with: BedrockModel.nova_micro,
                prompt: prompt,
                temperature: temperature
            )
        }
    }

    // MaxTokens
    @Test(
        "Continue conversation using a valid maxTokens",
        arguments: NovaTestConstants.TextGeneration.validMaxTokens
    )
    func converseWithValidMaxTokens(maxTokens: Int) async throws {
        let prompt = "This is a test"
        let (output, _) = try await bedrock.converse(
            with: BedrockModel.nova_micro,
            prompt: prompt,
            maxTokens: maxTokens
        )
        #expect(output == "Your prompt was: \(prompt)")
    }

    @Test(
        "Continue conversation variation using an invalid maxTokens",
        arguments: NovaTestConstants.TextGeneration.invalidMaxTokens
    )
    func converseWithInvalidMaxTokens(maxTokens: Int) async throws {
        await #expect(throws: BedrockServiceError.self) {
            let prompt = "This is a test"
            let _ = try await bedrock.converse(
                with: BedrockModel.nova_micro,
                prompt: prompt,
                maxTokens: maxTokens
            )
        }
    }

    // TopP
    @Test(
        "Continue conversation using a valid temperature",
        arguments: NovaTestConstants.TextGeneration.validTopP
    )
    func converseWithValidTopP(topP: Double) async throws {
        let prompt = "This is a test"
        let (output, _) = try await bedrock.converse(
            with: BedrockModel.nova_micro,
            prompt: prompt,
            topP: topP
        )
        #expect(output == "Your prompt was: \(prompt)")
    }

    @Test(
        "Continue conversation variation using an invalid temperature",
        arguments: NovaTestConstants.TextGeneration.invalidTopP
    )
    func converseWithInvalidTopP(topP: Double) async throws {
        await #expect(throws: BedrockServiceError.self) {
            let prompt = "This is a test"
            let _ = try await bedrock.converse(
                with: BedrockModel.nova_micro,
                prompt: prompt,
                topP: topP
            )
        }
    }

    // StopSequences
    @Test(
        "Continue conversation using a valid stopSequences",
        arguments: NovaTestConstants.TextGeneration.validStopSequences
    )
    func converseWithValidTopK(stopSequences: [String]) async throws {
        let prompt = "This is a test"
        let (output, _) = try await bedrock.converse(
            with: BedrockModel.nova_micro,
            prompt: prompt,
            stopSequences: stopSequences
        )
        #expect(output == "Your prompt was: \(prompt)")
    }
}
