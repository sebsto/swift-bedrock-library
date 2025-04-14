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

@testable import BedrockTypes

// MARK: JSON
extension BedrockServiceTests {

    @Test("JSON getValue")
    func jsonGetValue() async throws {
        let json = JSON([
            "name": JSON("Jane Doe"),
            "age": JSON(30),
            "isMember": JSON(true),
        ])
        #expect(json.getValue("name") == "Jane Doe")
        #expect(json.getValue("age") == 30)
        #expect(json.getValue("isMember") == true)
        #expect(json.getValue("nonExistentKey") == nil)
    }

    @Test("JSON Subscript")
    func jsonSubscript() async throws {
        let json = JSON([
            "name": JSON("Jane Doe"),
            "age": JSON(30),
            "isMember": JSON(true),
        ])
        #expect(json["name"].value as? String == "Jane Doe")
        #expect(json["age"].value as? Int == 30)
        #expect(json["isMember"].value as? Bool == true)
        #expect(json["nonExistentKey"].value == nil)
    }

    @Test("JSON String Initializer with Valid String")
    func jsonStringInitializer() async throws {
        let validJSONString = """
            {
                "name": "Jane Doe",
                "age": 30,
                "isMember": true
            }
            """

        let json = try JSON(from: validJSONString)
        #expect(json.getValue("name") == "Jane Doe")
        #expect(json.getValue("age") == 30)
        #expect(json.getValue("isMember") == true)
    }

    @Test("JSON String Initializer with Invalid String")
    func jsonInvalidStringInitializer() async throws {
        let invalidJSONString = """
            {
                "name": "Jane Doe",
                "age": 30,
                "isMember": true,
            """  // Note: trailing comma, making this invalid
        #expect(throws: BedrockServiceError.self) {
            let _ = try JSON(from: invalidJSONString)
        }
    }
}

