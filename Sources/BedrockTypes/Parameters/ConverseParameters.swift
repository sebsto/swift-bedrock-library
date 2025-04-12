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

import Foundation

public struct ConverseParameters: Parameters {
    public let temperature: Parameter<Double>
    public let maxTokens: Parameter<Int>
    public let topP: Parameter<Double>
    public let prompt: PromptParams
    public let stopSequences: StopSequenceParams

    public init(
        temperature: Parameter<Double>,
        maxTokens: Parameter<Int>,
        topP: Parameter<Double>,
        stopSequences: StopSequenceParams,
        maxPromptSize: Int?
    ) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.prompt = PromptParams(maxSize: maxPromptSize)
        self.stopSequences = stopSequences
    }

    public init(textGenerationParameters: TextGenerationParameters) {
        self.temperature = textGenerationParameters.temperature
        self.maxTokens = textGenerationParameters.maxTokens
        self.topP = textGenerationParameters.topP
        self.prompt = textGenerationParameters.prompt
        self.stopSequences = textGenerationParameters.stopSequences
    }
}
