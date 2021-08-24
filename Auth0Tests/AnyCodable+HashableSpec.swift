//
//  UserInfo+HashableSpec.swift
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

class AnyCodableHashableSpec: QuickSpec {
    override func spec() {

        describe("compare AnyCodable instances hash") {
            it("should be equal for bool") {
                let a = AnyCodable(true)
                let b = AnyCodable(true)

                expect(a.hashValue) == b.hashValue
            }

            it("should be equal for String") {
                let a = AnyCodable(Sub)
                let b = AnyCodable(Sub)

                expect(a.hashValue) == b.hashValue
            }

            it("should be equal for Int") {
                let a = AnyCodable(10)
                let b = AnyCodable(10)

                expect(a.hashValue) == b.hashValue
            }

            it("should be equal for Double") {
                let a = AnyCodable(UpdatedAtTimestamp)
                let b = AnyCodable(UpdatedAtTimestamp)

                expect(a.hashValue) == b.hashValue
            }

            it("should be equal for sorted Arrays") {
                let a = AnyCodable([1, true, "String"])
                let b = AnyCodable([1, true, "String"])

                expect(a.hashValue) == b.hashValue
            }

            it("should be equal for unsorted Arrays") {
                let a = AnyCodable([1, true, "String"])
                let b = AnyCodable([true, "String", 1])

                expect(a.hashValue) == b.hashValue
            }

            it("should be equal for Dictionaries") {
                let a: [String: AnyCodable] = ["key1": 1, "key2": true, "key3": "value3"]
                let b: [String: AnyCodable] = ["key1": 1, "key2": true, "key3": "value3"]

                expect(a.hashValue) == b.hashValue
            }

            it("should not be equal for Dictionaries with at least one different value") {
                let a: [String: AnyCodable] = ["key1": 1, "key2": true, "key3": "value3"]
                let b: [String: AnyCodable] = ["key1": 1, "key2": false, "key3": "value3"]

                expect(a.hashValue) != b.hashValue
            }

            it("should not be equal if there are not from the same type") {
                let a = AnyCodable(10)
                let b = AnyCodable("10")

                expect(a.hashValue) != b.hashValue
            }
        }
    }
}
