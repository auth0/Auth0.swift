//
//  AnyCodableSpec.swift
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

class AnyCodableSpec: QuickSpec {
    override func spec() {

        describe("init from AnyDecodable") {
            it("should be created from a Bool") {

                let value = true
                let data = try! JSONEncoder().encode(value)

                let decodable: AnyDecodable? = try JSONDecoder().decode(AnyDecodable.self, from: data)

                let b = decodable?.value as? Bool ?? false

                expect(value).to(be(b))
            }

            it("should be created from a String") {

                let value = "A String"
                let data = try! JSONEncoder().encode(value)

                let decodable: AnyDecodable? = try JSONDecoder().decode(AnyDecodable.self, from: data)

                let b = decodable?.value as? String

                expect(value) == b
            }

            it("should be created from an UInt64") {

                let value: UInt64 = 10
                let data = try! JSONEncoder().encode(value)

                let decodable: AnyDecodable? = try JSONDecoder().decode(AnyDecodable.self, from: data)

                let b = UInt64(decodable?.value as! Int)

                expect(value) == b
            }

            it("should be created from an Int64") {

                let value: Int64 = 10
                let data = try! JSONEncoder().encode(value)

                let decodable: AnyDecodable? = try JSONDecoder().decode(AnyDecodable.self, from: data)

                let b = Int64(decodable?.value as! Int)

                expect(value) == b
            }

            it("should be created from an Float") {

                let value: Float = 1.23456789
                let data = try! JSONEncoder().encode(value)

                let decodable: AnyDecodable? = try JSONDecoder().decode(AnyDecodable.self, from: data)

                let b = Float(decodable?.value as! Double)

                expect(value) == b
            }

            it("should be created from an Double") {

                let value: Double = 1.23456789
                let data = try! JSONEncoder().encode(value)

                let decodable: AnyDecodable? = try JSONDecoder().decode(AnyDecodable.self, from: data)

                let b = decodable?.value as? Double

                expect(value) == b
            }
            
            it ("should be created from a JSON String") {
                let json = """
                {
                    "boolean": true,
                    "integer": 42,
                    "double": 1.23,
                    "string": "string",
                    "array": [1, 2, 3],
                    "nested": {
                        "a": "alpha",
                        "b": "bravo",
                        "c": "charlie"
                    },
                    "null": null
                }
                """.data(using: .utf8)!

                let decoder = JSONDecoder()
                let dictionary = try! decoder.decode([String: AnyDecodable].self, from: json)
                
                let bool = dictionary["boolean"]?.value
                let integer = dictionary["integer"]?.value
                let double = dictionary["double"]?.value as? Double
                let string = dictionary["string"]?.value as? String
                let array = dictionary["array"]?.value as? [Int]
                let nested = dictionary["nested"]?.value as? [String: Any]
                let null = dictionary["null"]?.value as? NSNull
                
                expect(bool).to(be(true))
                expect(integer).to(be(42))
                expect(double) == 1.23
                expect(string).to(be("string"))
                expect(array?.count).to(be(3))
                expect(array) == [1, 2, 3]
                expect(nested?.count).to(be(3))
                expect(nested?["a"]).to(be("alpha"))
                expect(nested?["b"]).to(be("bravo"))
                expect(nested?["c"]).to(be("charlie"))
                expect(null?.isKind(of: NSNull.self)).to(beTrue())
            }
        }
            
        describe("init from AnyCodable") {
            it("should be created from an array") {

                let value: [AnyCodable] = [1, true, "String"]
                let data = try! JSONEncoder().encode(value)

                let b = try? JSONDecoder().decode([AnyCodable].self, from: data)

                expect(value[0] == b?[0]).to(beTrue())
                expect(value[1] == b?[1]).to(beTrue())
                expect(value[2] == b?[2]).to(beTrue())
            }
            
            it("should be created from a dictionary") {

                let value: [String: AnyCodable] = ["key1": 1, "key2": true, "key3": "String"]
                let data = try! JSONEncoder().encode(value)

                let b = try? JSONDecoder().decode([String:AnyCodable].self, from: data)
                
                expect(value["key1"] == b?["key1"]).to(beTrue())
            }
        }
    }
}
