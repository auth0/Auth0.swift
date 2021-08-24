//
//  AnyCodable+StringConvertibleSpec.swift
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

class AnyCodableStringConvertibleSpec: QuickSpec {
    override func spec() {

        describe("print the description of a AnyCodable instances") {
            it("should not start with \"AnyCodable") {
                let value = true
                let a = AnyCodable(value)

                expect(a.description.starts(with: "AnyCodable")).to(be(false))
                expect(a.description) == "\(value)"
            }

            it("should describe the content of an instance that implements CustomStringConvertible") {
                let value: CustomStringConvertible = "A String to test"
                let a = AnyCodable(value)

                expect(a.description) == value.description
            }
        }

        describe("print the debug description of a AnyCodable instances") {
            it("should start with \"AnyCodable") {
                let a = AnyCodable(true)

                expect(a.debugDescription.starts(with: "AnyCodable")).to(be(true))
            }
            it("should contain value between parentesis") {
                let a = AnyCodable(true).debugDescription.replacingOccurrences(of: "AnyCodable", with: "")

                expect(a.hasPrefix("(")).to(be(true))
                expect(a.hasSuffix(")")).to(be(true))
            }

            it("should describe the content of a Bool") {
                let a = AnyCodable(true)

                expect(a.debugDescription) == "AnyCodable(true)"
            }

            it("should describe the content of an instance that implements CustomDebugStringConvertible") {
                let value: CustomDebugStringConvertible = "A String to test"
                let a = AnyCodable(value)

                expect(a.debugDescription) == "AnyCodable(\(value.debugDescription))"
            }
        }
    }
}
