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
import Foundation

public struct ImageBlock: Codable {
    public let format: Format
    public let source: String  // 64 encoded

    public init(format: Format, source: String) {
        self.format = format
        self.source = source
    }

    public init(from sdkImageBlock: BedrockRuntimeClientTypes.ImageBlock) throws {
        guard let sdkFormat = sdkImageBlock.format else {
            throw BedrockServiceError.decodingError(
                "Could not extract format from BedrockRuntimeClientTypes.ImageBlock"
            )
        }
        guard let sdkImageSource = sdkImageBlock.source else {
            throw BedrockServiceError.decodingError(
                "Could not extract source from BedrockRuntimeClientTypes.ImageBlock"
            )
        }
        let format = try ImageBlock.Format(from: sdkFormat)
        switch sdkImageSource {
        case .bytes(let data):
            self = ImageBlock(format: format, source: data.base64EncodedString())
        case .sdkUnknown(let unknownImageSource):
            throw BedrockServiceError.notImplemented(
                "ImageSource \(unknownImageSource) is not implemented by BedrockRuntimeClientTypes"
            )
        }
    }

    public func getSDKImageBlock() throws -> BedrockRuntimeClientTypes.ImageBlock {
        guard let data = Data(base64Encoded: source) else {
            throw BedrockServiceError.decodingError(
                "Could not decode image source from base64 string. String: \(source)"
            )
        }
        return BedrockRuntimeClientTypes.ImageBlock(
            format: format.getSDKImageFormat(),
            source: BedrockRuntimeClientTypes.ImageSource.bytes(data)
        )
    }

    public enum Format: Codable {
        case gif
        case jpeg
        case png
        case webp

        public init(from sdkImageFormat: BedrockRuntimeClientTypes.ImageFormat) throws {
            switch sdkImageFormat {
            case .gif: self = .gif
            case .jpeg: self = .jpeg
            case .png: self = .png
            case .webp: self = .webp
            case .sdkUnknown(let unknownImageFormat):
                throw BedrockServiceError.notImplemented(
                    "ImageFormat \(unknownImageFormat) is not implemented by BedrockRuntimeClientTypes"
                )
            }
        }

        public func getSDKImageFormat() -> BedrockRuntimeClientTypes.ImageFormat {
            switch self {
            case .gif: return .gif
            case .jpeg: return .jpeg
            case .png: return .png
            case .webp: return .webp
            }
        }
    }
}
