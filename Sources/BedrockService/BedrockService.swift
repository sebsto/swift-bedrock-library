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
import AwsCommonRuntimeKit
import BedrockTypes
import Foundation
import Logging
import SmithyIdentity

public struct BedrockService: Sendable {
    package let region: Region
    package let logger: Logging.Logger
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
    ///   - profileName: Optional profile name to use for AWS credentials
    /// - Throws: Error if client initialization fails
    public init(
        region: Region = .useast1,
        logger: Logging.Logger? = nil,
        bedrockClient: BedrockClientProtocol? = nil,
        bedrockRuntimeClient: BedrockRuntimeClientProtocol? = nil,
        useSSO: Bool = false,
        profileName: String? = nil
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
                profileName: profileName
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
                profileName: profileName
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

    /// Creates Logger using either the loglevel saved as environment variable `BEDROCK_SERVICE_LOG_LEVEL` or with default `.info`
    /// - Parameter name: The name/label for the logger
    /// - Returns: Configured Logger instance
    static private func createLogger(_ name: String) -> Logging.Logger {
        var logger: Logging.Logger = Logger(label: name)
        logger.logLevel =
            ProcessInfo.processInfo.environment["BEDROCK_SERVICE_LOG_LEVEL"].flatMap {
                Logger.Level(rawValue: $0.lowercased())
            } ?? .info
        return logger
    }

    /// Creates a BedrockClient
    /// - Parameters:
    ///   - region: The AWS region to configure the client for
    ///   - useSSO: Whether to use SSO authentication
    ///   - profileName: Optional profile name to use for AWS credentials
    /// - Returns: Configured BedrockClientProtocol instance
    /// - Throws: Error if client creation fails
    static private func createBedrockClient(
        region: Region,
        useSSO: Bool = false,
        profileName: String? = nil
    ) async throws
        -> BedrockClientProtocol
    {
        let config = try await BedrockClient.BedrockClientConfiguration(
            region: region.rawValue
        )
        if let awsCredentialIdentityResolver = try? getAWSCredentialIdentityResolver(
            useSSO: useSSO,
            profileName: profileName
        ) {
            config.awsCredentialIdentityResolver = awsCredentialIdentityResolver
        }
        return BedrockClient(config: config)
    }

    /// Creates a BedrockRuntimeClient
    /// - Parameters:
    ///   - region: The AWS region to configure the client for
    ///   - useSSO: Whether to use SSO authentication
    ///   - profileName: Optional profile name to use for AWS credentials
    /// - Returns: Configured BedrockRuntimeClientProtocol instance
    /// - Throws: Error if client creation fails
    static private func createBedrockRuntimeClient(
        region: Region,
        useSSO: Bool = false,
        profileName: String? = nil
    )
        async throws
        -> BedrockRuntimeClientProtocol
    {
        let config =
            try await BedrockRuntimeClient.BedrockRuntimeClientConfiguration(
                region: region.rawValue
            )
        if let awsCredentialIdentityResolver = try? getAWSCredentialIdentityResolver(
            useSSO: useSSO,
            profileName: profileName
        ) {
            config.awsCredentialIdentityResolver = awsCredentialIdentityResolver
        }
        return BedrockRuntimeClient(config: config)
    }

    /// Creates an AWS credential identity resolver depending on the provided parameters.
    /// If `useSSO` is false and no `profileName` is provided, nil is returned, causing the client to use the defaultchain.
    /// If `useSSO` is false and a `profileName` is provided, `ProfileAWSCredentialIdentityResolver` is returned.
    /// If `useSSO` is true, `SSOAWSCredentialIdentityResolver` is configured (with the `profileName`) and returned.
    /// - Parameters:
    ///   - useSSO: Whether to use SSO authentication
    ///   - profileName: Optional profile name to use for AWS credentials
    /// - Returns: Configured AWSCredentialIdentityResolver instance or nil
    /// - Throws: Error if AWSCredentialIdentityResolver creation fails
    static private func getAWSCredentialIdentityResolver(
        useSSO: Bool,
        profileName: String? = nil
    ) throws -> (any SmithyIdentity.AWSCredentialIdentityResolver)? {
        if useSSO {
            return try SSOAWSCredentialIdentityResolver(profileName: profileName)
        } else if let profileName {
            return try ProfileAWSCredentialIdentityResolver(profileName: profileName)
        } else {
            return nil
        }
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

        } catch let commonError as CommonRunTimeError {
            switch commonError {
            case .crtError(let crtError):
                switch crtError.code {
                case 6153:
                    throw BedrockServiceError.authenticationFailed(
                        "No valid credentials found: \(crtError.message)"
                    )
                case 6170:
                    throw BedrockServiceError.authenticationFailed(
                        "AWS SSO token expired: \(crtError.message)"
                    )
                default:
                    throw BedrockServiceError.authenticationFailed(
                        "Authentication failed: \(crtError.message)"
                    )
                }
            }
        } catch {
            logger.trace("Error while listing foundation models", metadata: ["error": "\(error)"])
            throw error
        }
    }
}
