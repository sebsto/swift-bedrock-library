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

import AwsCommonRuntimeKit
import Testing

@testable import BedrockService
@testable import BedrockTypes

// MARK: authentication
extension BedrockServiceTests {

    @Test("Authentication Error: no valid credentials")
    func authErrorNoValidCredentials() async throws {
        await #expect(throws: BedrockServiceError.self) {
            let bedrock = try await BedrockService()
            let _ = try await bedrock.listModels()
        }
    }

    // Only works when SSO is actually expired
    // @Test("Authentication Error: SSO expired")
    // func authErrorSSOExpired() async throws {
    //     await #expect(throws: BedrockServiceError.self) {
    //         let bedrock = try await BedrockService(useSSO: true)
    //         let _ = try await bedrock.listModels()
    //     }
    // }
}
