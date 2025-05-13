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
extension BedrockTypesTests {

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

    @Test("JSON getValue nested")
    func jsonGetValueNested() async throws {
        let json = JSON([
            "name": JSON("Jane Doe"),
            "age": JSON(30),
            "isMember": JSON(true),
            "address": JSON([
                "street": JSON("123 Main St"),
                "city": JSON("Anytown"),
                "state": JSON("CA"),
                "zip": JSON("12345")
            ])
        ])
        #expect(json.getValue("name") == "Jane Doe")
        #expect(json.getValue("age") == 30)
        #expect(json.getValue("isMember") == true)
        #expect(json.getValue("nonExistentKey") == nil)

        let address = JSON(json.getValue("address"))
        #expect(address.getValue("street") == "123 Main St")
    }

    @Test("JSON Subscript")
    func jsonSubscript() async throws {
        let json = JSON([
            "name": JSON("Jane Doe"),
            "age": JSON(30),
            "isMember": JSON(true),
        ])
        #expect(json["name"] == "Jane Doe")
        #expect(json["age"] == 30)
        #expect(json["isMember"] == true)
        #expect(json["nonExistentKey"] == nil)
    }

    @Test("JSON Subscript nested")
    func jsonSubscriptNested() async throws {
        let json = JSON([
            "name": JSON("Jane Doe"),
            "age": JSON(30),
            "isMember": JSON(true),
            "address": JSON([
                "street": JSON("123 Main St"),
                "city": JSON("Anytown"),
                "state": JSON("CA"),
                "zip": JSON(12345),
                "isSomething": JSON(true)
            ])
        ])
        #expect(json["name"] == "Jane Doe")
        #expect(json["age"] == 30)
        #expect(json["isMember"] == true)
        #expect(json["nonExistentKey"] == nil)
        
        let address = JSON(json["address"])
        #expect(address["street"] == "123 Main St")
        #expect(address["isSomething"] == true)
        
        let zip: Int? = address["zip"]
        #expect(zip == 12345)

        let isSomething: Bool? = address["isSomething"]
        #expect(isSomething == true)
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
