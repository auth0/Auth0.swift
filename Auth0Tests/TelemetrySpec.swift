// TelemetrySpec.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Quick
import Nimble

@testable import Auth0

class TelemetrySpec: QuickSpec {

    override func spec() {

        var telemetry: Telemetry!

        beforeEach {
            telemetry = Telemetry()
        }

        it("should be enabled by default") {
            expect(telemetry.enabled) == true
        }

        it("should have a default value") {
            expect(telemetry.value).toNot(beEmpty())
        }

        it("should have a valid base64 value") {
            expect(telemetry.value).to(beURLSafeBase64())
        }

        it("should have nil value when disabled") {
            telemetry.enabled = false
            expect(telemetry.value).to(beNil())
        }

        it("should have a valid base64 value after re-enabling telemetry") {
            telemetry.enabled = false
            telemetry.enabled = true
            expect(telemetry.value).to(beURLSafeBase64())
        }

        describe("versionInformation") {

            let bundle = MockedBundle()

            beforeEach {
                bundle.version = nil
            }

            var subject: [String: String] {
                return Telemetry.versionInformation(bundle: bundle)
            }

            pending("should return bundle default version if nil") {
                expect(subject["version"]) == "0.0.0"
            }

            pending("should return bundle version") {
                bundle.version = "1.0.0"
                expect(subject["version"]) == "1.0.0"
            }

            it("should return lib name") {
                expect(subject["name"]) == "Auth0.swift"
            }

        }

        describe("wrapping") {

            var telemetry = Telemetry()
            let version = Telemetry.versionInformation()["version"] ?? Telemetry.NoVersion

            beforeEach {
                telemetry.wrapped(in: "Lock.iOS", version: "1.0.0-alpha.4")
            }

            it("should have a valid base64 value") {
                expect(telemetry.value).to(beURLSafeBase64())
            }

            it("should have correct info") {
                let value = telemetry.value!
                    .stringByReplacingOccurrencesOfString("-", withString: "+")
                    .stringByReplacingOccurrencesOfString("_", withString: "/")
                let paddedLength: Int
                let padding = value.characters.count % 4
                if padding > 0 {
                    paddedLength = value.characters.count + (4 - padding)
                } else {
                    paddedLength = value.characters.count
                }
                let padded = value.stringByPaddingToLength(paddedLength, withString: "=", startingAtIndex: 0)

                let data = NSData(base64EncodedString: padded, options: [NSDataBase64DecodingOptions.IgnoreUnknownCharacters])
                let info = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: String]
                expect(info["version"]) == "1.0.0-alpha.4"
                expect(info["lib_version"]) == version
                expect(info["name"]) == "Lock.iOS"
            }
        }

        describe("telemetry header") {

            var telemetry = Telemetry()

            it("should set telemetry header") {
                let request = NSMutableURLRequest()
                telemetry.addTelemetryHeader(request: request)
                expect(request.valueForHTTPHeaderField("Auth0-Client")) == telemetry.value
            }

            it("should not set telemetry header when disabled") {
                let request = NSMutableURLRequest()
                telemetry.enabled = false
                telemetry.addTelemetryHeader(request: request)
                expect(request.valueForHTTPHeaderField("Auth0-Client")).to(beNil())
            }

        }

        describe("telemetry query item") {

            var telemetry: Telemetry!

            beforeEach {
                telemetry = Telemetry()
            }

            it("should set telemetry header") {
                let items = telemetry.queryItemsWithTelemetry(queryItems: [])
                expect(items.first) == NSURLQueryItem(name: "auth0Client", value: telemetry.value)
            }

            it("should not set telemetry header when disabled") {
                telemetry.enabled = false
                let items = telemetry.queryItemsWithTelemetry(queryItems: [])
                expect(items).to(beEmpty())
            }

            it("should keep items already in list when adding item") {
                let item = NSURLQueryItem(name: "key", value: "value")
                let items = telemetry.queryItemsWithTelemetry(queryItems: [item])
                expect(items).to(contain(NSURLQueryItem(name: "auth0Client", value: telemetry.value)))
                expect(items).to(contain(item))
            }

            it("should keep items already in list when skipping telemetry") {
                telemetry.enabled = false
                let item = NSURLQueryItem(name: "key", value: "value")
                let items = telemetry.queryItemsWithTelemetry(queryItems: [item])
                expect(items).toNot(contain(NSURLQueryItem(name: "auth0Client", value: telemetry.value)))
                expect(items).to(contain(item))
            }

        }

        describe("trackable") {
            struct MockTrackable: Trackable {
                var telemetry: Telemetry
            }

            var trackable: Trackable!

            beforeEach {
                trackable = MockTrackable(telemetry: telemetry)
            }

            it("should toggle telemetry") {
                trackable.tracking(enabled: false)
                expect(trackable.telemetry.enabled) == false
                trackable.tracking(enabled: true)
                expect(trackable.telemetry.enabled) == true
            }

            it("should mark it as used inside other library") {
                let info = trackable.telemetry.info
                trackable.using(in: "Lock.swift", version: "2.0.0-alpha.0")
                expect(trackable.telemetry.info) != info
            }
        }

    }

}


class MockedBundle: NSBundle {

    var version: String? = nil

    override var infoDictionary: [String : AnyObject]? {
        if let version = self.version {
            return [
                "CFBundleShortVersionString": version
            ]
        }
        return nil
    }
}
