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

@preconcurrency import AWSBedrock
@preconcurrency import AWSBedrockRuntime
import AWSClientRuntime
import AWSSDKIdentity
import BedrockTypes
import Foundation
import Logging

public struct BedrockService: Sendable {
    package let region: Region
    package let logger: Logger
    package let bedrockClient: BedrockClientProtocol
    package let bedrockRuntimeClient: BedrockRuntimeClientProtocol

    // MARK: - Initialization

    /// Initializes a new SwiftBedrock instance
    /// - Parameters:
    ///   - region: The AWS region to use (defaults to .useast1)
    ///   - logger: Optional custom logger instance
    ///   - bedrockClient: Optional custom Bedrock client
    ///   - bedrockRuntimeClient: Optional custom Bedrock Runtime client
    ///   - useSSO: Whether to use SSO authentication (defaults to false)
    /// - Throws: Error if client initialization fails
    public init(
        region: Region = .useast1,
        logger: Logger? = nil,
        bedrockClient: BedrockClientProtocol? = nil,
        bedrockRuntimeClient: BedrockRuntimeClientProtocol? = nil,
        useSSO: Bool = false,
        ssoProfileName: String? = nil
    ) async throws {
        self.logger = logger ?? BedrockService.createLogger("bedrock.service")
        self.logger.trace(
            "Initializing SwiftBedrock",
            metadata: ["region": .string(region.rawValue)]
        )
        self.region = region

        if bedrockClient != nil {
            self.logger.trace("Using supplied bedrockClient")
            self.bedrockClient = bedrockClient!
        } else {
            self.logger.trace("Creating bedrockClient")
            self.bedrockClient = try await BedrockService.createBedrockClient(
                region: region,
                useSSO: useSSO,
                ssoProfileName: ssoProfileName
            )
            self.logger.trace(
                "Created bedrockClient",
                metadata: ["useSSO": "\(useSSO)"]
            )
        }
        if bedrockRuntimeClient != nil {
            self.logger.trace("Using supplied bedrockRuntimeClient")
            self.bedrockRuntimeClient = bedrockRuntimeClient!
        } else {
            self.logger.trace("Creating bedrockRuntimeClient")
            self.bedrockRuntimeClient = try await BedrockService.createBedrockRuntimeClient(
                region: region,
                useSSO: useSSO,
                ssoProfileName: ssoProfileName
            )
            self.logger.trace(
                "Created bedrockRuntimeClient",
                metadata: ["useSSO": "\(useSSO)"]
            )
        }
        self.logger.trace(
            "Initialized SwiftBedrock",
            metadata: ["region": .string(region.rawValue)]
        )
    }

    // MARK: - Private Helpers

    /// Creates Logger using either the loglevel saved as environment variable `BEDROCK_SERVICE_LOG_LEVEL` or with default `.trace`
    /// - Parameter name: The name/label for the logger
    /// - Returns: Configured Logger instance
    static private func createLogger(_ name: String) -> Logger {
        var logger: Logger = Logger(label: name)
        logger.logLevel =
            ProcessInfo.processInfo.environment["BEDROCK_SERVICE_LOG_LEVEL"].flatMap {
                Logger.Level(rawValue: $0.lowercased())
            } ?? .trace  // FIXME: trace for me, later .info
        return logger
    }

    /// Creates a BedrockClient
    /// - Parameters:
    ///   - region: The AWS region to configure the client for
    ///   - useSSO: Whether to use SSO authentication
    /// - Returns: Configured BedrockClientProtocol instance
    /// - Throws: Error if client creation fails
    static private func createBedrockClient(
        region: Region,
        useSSO: Bool = false,
        ssoProfileName: String? = nil
    ) async throws
        -> BedrockClientProtocol
    {
        let config = try await BedrockClient.BedrockClientConfiguration(
            region: region.rawValue
        )
        if useSSO {
            config.awsCredentialIdentityResolver = try SSOAWSCredentialIdentityResolver(profileName: ssoProfileName)
        }
        return BedrockClient(config: config)
    }

    /// Creates a BedrockRuntimeClient
    /// - Parameters:
    ///   - region: The AWS region to configure the client for
    ///   - useSSO: Whether to use SSO authentication
    /// - Returns: Configured BedrockRuntimeClientProtocol instance
    /// - Throws: Error if client creation fails
    static private func createBedrockRuntimeClient(
        region: Region,
        useSSO: Bool = false,
        ssoProfileName: String? = nil
    )
        async throws
        -> BedrockRuntimeClientProtocol
    {
        let config =
            try await BedrockRuntimeClient.BedrockRuntimeClientConfiguration(
                region: region.rawValue
            )
        if useSSO {
            config.awsCredentialIdentityResolver = try SSOAWSCredentialIdentityResolver(profileName: ssoProfileName)
        }
        return BedrockRuntimeClient(config: config)
    }

    // MARK: Public Methods

    /// Lists all available foundation models from Amazon Bedrock
    /// - Throws: BedrockServiceError.invalidResponse
    /// - Returns: An array of ModelSummary objects containing details about each available model
    public func listModels() async throws -> [ModelSummary] {
        logger.trace("Fetching foundation models")
        do {
            let response = try await bedrockClient.listFoundationModels(
                input: ListFoundationModelsInput()
            )
            guard let models = response.modelSummaries else {
                logger.trace("Failed to extract modelSummaries from response")
                throw BedrockServiceError.invalidSDKResponse(
                    "Something went wrong while extracting the modelSummaries from the response."
                )
            }
            var modelsInfo: [ModelSummary] = []
            modelsInfo = try models.compactMap { (sdkModelSummary) -> ModelSummary? in
                try ModelSummary.getModelSummary(from: sdkModelSummary)
            }
            logger.trace(
                "Fetched foundation models",
                metadata: [
                    "models.count": "\(modelsInfo.count)",
                    "models.content": .string(String(describing: modelsInfo)),
                ]
            )
            return modelsInfo
        } catch {
            logger.trace("Error while listing foundation models", metadata: ["error": "\(error)"])
            throw error
        }
    }
}
