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

public protocol Parameters: Sendable, Hashable, Equatable {}

public struct Parameter<T: Sendable & Hashable & Equatable & Numeric>: Sendable, Hashable, Equatable {
    public let minValue: T?
    public let maxValue: T?
    public let defaultValue: T?
    public let isSupported: Bool
    public let name: ParameterName

    public init(_ name: ParameterName, minValue: T? = nil, maxValue: T? = nil, defaultValue: T? = nil) {
        self = Self(name: name, minValue: minValue, maxValue: maxValue, defaultValue: defaultValue, isSupported: true)
    }

    public static func notSupported(_ name: ParameterName) -> Self {
        Self(name: name, minValue: nil, maxValue: nil, defaultValue: nil, isSupported: false)
    }

    private init(name: ParameterName, minValue: T? = nil, maxValue: T? = nil, defaultValue: T? = nil, isSupported: Bool)
    {
        self.minValue = minValue
        self.maxValue = maxValue
        self.defaultValue = defaultValue
        self.isSupported = isSupported
        self.name = name
    }
}

public enum ParameterName: Sendable {
    case maxTokens
    case temperature
    case topK
    case topP
    case nrOfImages
    case images
    case similarity
    case cfgScale
    case seed
    case resolution
}

public struct PromptParams: Parameters {
    public let maxSize: Int?
}

public struct StopSequenceParams: Parameters {
    public let maxSequences: Int?
    public let defaultValue: [String]?
    public let isSupported: Bool

    public init(maxSequences: Int? = nil, defaultValue: [String]? = nil) {
        self = Self(maxSequences: maxSequences, defaultValue: defaultValue, isSupported: true)
    }

    public static func notSupported() -> Self {
        Self(maxSequences: nil, defaultValue: nil, isSupported: false)
    }

    private init(maxSequences: Int? = nil, defaultValue: [String]? = nil, isSupported: Bool = true) {
        self.maxSequences = maxSequences
        self.defaultValue = defaultValue
        self.isSupported = isSupported
    }
}
