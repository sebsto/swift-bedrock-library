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

public struct DocumentBlock: Codable {
    public let name: String
    public let format: Format
    public let source: String  // 64 encoded

    public init(name: String, format: Format, source: String) throws {
        // https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_DocumentBlock.html
        guard !name.isEmpty else {
            throw BedrockServiceError.invalidName("Document name is not allowed to be empty")
        }
        guard name.contains(/^[a-zA-Z()\[\]\-](?:[a-zA-Z()\[\]\-]|\s(?!\s))*$/) else {
            throw BedrockServiceError.invalidName(
                "Document name must consist of only lowercase letter, uppercase letters, parentheses, square brackets, whitespace characters (no more than one in a row) and hyphens"
            )
        }
        guard name.count <= 200 else {
            throw BedrockServiceError.invalidName("Document name must be no longer than 200 characters")
        }
        guard !source.isEmpty else {
            throw BedrockServiceError.invalidName("Document source is not allowed to be empty")
        }

        self.name = name
        self.format = format
        self.source = source
    }

    public init(from sdkDocumentBlock: BedrockRuntimeClientTypes.DocumentBlock) throws {
        guard let sdkDocumentSource = sdkDocumentBlock.source else {
            throw BedrockServiceError.decodingError(
                "Could not extract source from BedrockRuntimeClientTypes.DocumentBlock"
            )
        }
        guard let name = sdkDocumentBlock.name else {
            throw BedrockServiceError.decodingError(
                "Could not extract name from BedrockRuntimeClientTypes.DocumentBlock"
            )
        }
        guard let sdkFormat = sdkDocumentBlock.format else {
            throw BedrockServiceError.decodingError(
                "Could not extract format from BedrockRuntimeClientTypes.DocumentBlock"
            )
        }
        let format = try DocumentBlock.Format(from: sdkFormat)
        switch sdkDocumentSource {
        case .bytes(let data):
            self = try DocumentBlock(name: name, format: format, source: data.base64EncodedString())
        case .sdkUnknown(let unknownImageSource):
            throw BedrockServiceError.notImplemented(
                "ImageSource \(unknownImageSource) is not implemented by BedrockRuntimeClientTypes"
            )
        }
    }

    public func getSDKDocumentBlock() throws -> BedrockRuntimeClientTypes.DocumentBlock {
        guard let data = Data(base64Encoded: source) else {
            throw BedrockServiceError.decodingError(
                "Could not decode document source from base64 string. String: \(source)"
            )
        }
        return BedrockRuntimeClientTypes.DocumentBlock(
            format: format.getSDKDocumentFormat(),
            name: name,
            source: BedrockRuntimeClientTypes.DocumentSource.bytes(data)
        )
    }

    public enum Format: Codable {
        case csv
        case doc
        case docx
        case html
        case md
        case pdf
        case txt
        case xls
        case xlsx

        public init(from sdkDocumentFormat: BedrockRuntimeClientTypes.DocumentFormat) throws {
            switch sdkDocumentFormat {
            case .csv: self = .csv
            case .doc: self = .doc
            case .docx: self = .docx
            case .html: self = .html
            case .md: self = .md
            case .pdf: self = .pdf
            case .txt: self = .txt
            case .xls: self = .xls
            case .xlsx: self = .xlsx
            case .sdkUnknown(let unknownDocumentFormat):
                throw BedrockServiceError.notImplemented(
                    "DocumentFormat \(unknownDocumentFormat) is not implemented by BedrockRuntimeClientTypes"
                )
            }
        }

        public func getSDKDocumentFormat() -> BedrockRuntimeClientTypes.DocumentFormat {
            switch self {
            case .csv: return .csv
            case .doc: return .doc
            case .docx: return .docx
            case .html: return .html
            case .md: return .md
            case .pdf: return .pdf
            case .txt: return .txt
            case .xls: return .xls
            case .xlsx: return .xlsx
            }
        }
    }
}
