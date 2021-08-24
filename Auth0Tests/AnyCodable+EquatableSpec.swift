//
//  AnyCodable+EquatableSpec.swift
//  Auth0
//
//  Created by Kimi on 24/8/21.
//  Copyright © 2021 Auth0. All rights reserved.
//

import Foundation
import Quick
import Nimble
import JWTDecode

@testable import Auth0

class AnyCodableEquatableSpec: QuickSpec {
    override func spec() {

        describe("compare AnyCodable instances") {
            it("should be equal for similar booleans") {
                let a = AnyCodable(true)
                let b = AnyCodable(true)

                expect(a) == b
            }

            it("should be equal for similar Strings") {
                let a: AnyCodable = "A String"
                let b = AnyCodable("A String")

                expect(a) == b
            }

            it("should be equal for similar Ints") {
                let a: AnyCodable = 10
                let b = AnyCodable(10)

                expect(a) == b
            }

            it("should be equal for similar Double") {
                let a = AnyCodable(1.2345)
                let b = AnyCodable(1.2345)

                expect(a) == b
            }

            it("should be equal for similar Arrays") {
                let a: [AnyCodable] = [1, true, "String"]
                let b: [AnyCodable] = [1, true, "String"]

                expect(a) == b
            }

            it("should be equal for unsorted Arrays") {
                let a: [AnyCodable] = [1, true, "String"]
                let b: [AnyCodable] = [1, true, "String"]

                expect(a) == b
            }

            it("should be equal for similar Dictionaries") {
                let a: [String: AnyCodable] = ["key2": true, "key3": "value3", "key1": 1]
                let b: [String: AnyCodable] = ["key1": 1, "key2": true, "key3": "value3"]

                expect(a) == b
            }

            it("should not be equal for different Strings") {
                let  a = AnyCodable("A String")
                let b = AnyCodable("Another String")

                expect(a) != b
            }
        }
    }
}
