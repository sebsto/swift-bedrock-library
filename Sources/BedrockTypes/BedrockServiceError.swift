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

public enum BedrockServiceError: Error {
    case invalidParameter(ParameterName, String)
    case invalidModality(BedrockModel, Modality, String)
    case invalidPrompt(String)
    case invalid(String)
    case invalidStopSequences([String], String)
    case invalidURI(String)
    case invalidConverseReply(String)
    case invalidName(String)
    case ConverseRequestBuilder(String)
    case invalidSDKResponse(String)
    case invalidSDKResponseBody(Data?)
    case completionNotFound(String)
    case encodingError(String)
    case decodingError(String)
    case notImplemented(String)
    case notSupported(String)
    case notFound(String)
    case authenticationFailed(String)
    case unknownError(String)
}
