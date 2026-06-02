import Foundation
import Quick
import Nimble

@testable import Auth0

class Auth0ClientInfoSpec: QuickSpec {

    override class func spec() {

        var auth0ClientInfo: Auth0ClientInfo!

        beforeEach {
            auth0ClientInfo = Auth0ClientInfo()
        }

        it("should be enabled by default") {
            expect(auth0ClientInfo.enabled) == true
        }

        it("should have a default value") {
            expect(auth0ClientInfo.value).toNot(beEmpty())
        }

        it("should have a valid base64 value") {
            expect(auth0ClientInfo.value).to(beURLSafeBase64())
        }

        it("should have nil value when disabled") {
            auth0ClientInfo.enabled = false
            expect(auth0ClientInfo.value).to(beNil())
        }

        it("should have a valid base64 value after re-enabling auth0ClientInfo") {
            auth0ClientInfo.enabled = false
            auth0ClientInfo.enabled = true
            expect(auth0ClientInfo.value).to(beURLSafeBase64())
        }

        describe("versionInformation") {

            var subject: [String: Any] {
                return Auth0ClientInfo.versionInformation()
            }

            it("should return lib name") {
                expect(subject["name"] as? String) == "Auth0.swift"
            }
            
            it("should have env info") {
                let env = subject["env"] as! [String : String]
                #if os(iOS)
                expect(env["iOS"]).toNot(beNil())
                #elseif os(OSX)
                expect(env["macOS"]).toNot(beNil())
                #elseif os(tvOS)
                expect(env["tvOS"]).toNot(beNil())
                #elseif os(watchOS)
                expect(env["watchOS"]).toNot(beNil())
                #elseif os(visionOS)
                expect(env["visionOS"]).toNot(beNil())
                #else
                expect(env["unknown"]).toNot(beNil())
                #endif
            }

        }

        describe("wrapping") {

            var auth0ClientInfo = Auth0ClientInfo()
            let version = Auth0ClientInfo.versionInformation()["version"]!

            beforeEach {
                auth0ClientInfo.wrapped(inLibrary: "Lock.iOS", version: "1.0.0-alpha.4")
            }

            it("should have a valid base64 value") {
                expect(auth0ClientInfo.value).to(beURLSafeBase64())
            }

            it("should have correct info") {
                let value = auth0ClientInfo.value!
                    .replacingOccurrences(of: "-", with: "+")
                    .replacingOccurrences(of: "_", with: "/")
                let paddedLength: Int
                let padding = value.count % 4
                if padding > 0 {
                    paddedLength = value.count + (4 - padding)
                } else {
                    paddedLength = value.count
                }
                let padded = value.padding(toLength: paddedLength, withPad: "=", startingAt: 0)

                let data = Data(base64Encoded: padded, options: [NSData.Base64DecodingOptions.ignoreUnknownCharacters])
                let info = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
                expect(info["version"] as? String) == "1.0.0-alpha.4"
                expect(info["name"] as? String) == "Lock.iOS"
                let env = info["env"] as! [String : String]
                expect(env["core"]) == version as? String
                #if os(iOS)
                expect(env["iOS"]).toNot(beNil())
                #elseif os(OSX)
                expect(env["macOS"]).toNot(beNil())
                #elseif os(tvOS)
                expect(env["tvOS"]).toNot(beNil())
                #elseif os(watchOS)
                expect(env["watchOS"]).toNot(beNil())
                #elseif os(visionOS)
                expect(env["visionOS"]).toNot(beNil())
                #else
                expect(env["unknown"]).toNot(beNil())
                #endif
            }

        }

        describe("auth0ClientInfo header") {

            it("should set auth0ClientInfo header") {
                let auth0ClientInfo = Auth0ClientInfo()
                let request = NSMutableURLRequest()
                auth0ClientInfo.addTelemetryHeader(request: request)
                expect(request.value(forHTTPHeaderField: "Auth0-Client")) == auth0ClientInfo.value
            }

            it("should not set auth0ClientInfo header when disabled") {
                var auth0ClientInfo = Auth0ClientInfo()
                let request = NSMutableURLRequest()
                auth0ClientInfo.enabled = false
                auth0ClientInfo.addTelemetryHeader(request: request)
                expect(request.value(forHTTPHeaderField: "Auth0-Client")).to(beNil())
            }

        }

        describe("auth0ClientInfo query item") {

            var auth0ClientInfo: Auth0ClientInfo!

            beforeEach {
                auth0ClientInfo = Auth0ClientInfo()
            }

            it("should set auth0ClientInfo header") {
                let items = auth0ClientInfo.queryItemsWithTelemetry(queryItems: [])
                expect(items.first) == URLQueryItem(name: "auth0Client", value: auth0ClientInfo.value)
            }

            it("should not set auth0ClientInfo header when disabled") {
                auth0ClientInfo.enabled = false
                let items = auth0ClientInfo.queryItemsWithTelemetry(queryItems: [])
                expect(items).to(beEmpty())
            }

            it("should keep items already in list when adding item") {
                let item = URLQueryItem(name: "key", value: "value")
                let items = auth0ClientInfo.queryItemsWithTelemetry(queryItems: [item])
                expect(items).to(contain(URLQueryItem(name: "auth0Client", value: auth0ClientInfo.value)))
                expect(items).to(contain(item))
            }

            it("should keep items already in list when skipping auth0ClientInfo") {
                auth0ClientInfo.enabled = false
                let item = URLQueryItem(name: "key", value: "value")
                let items = auth0ClientInfo.queryItemsWithTelemetry(queryItems: [item])
                expect(items).toNot(contain(URLQueryItem(name: "auth0Client", value: auth0ClientInfo.value)))
                expect(items).to(contain(item))
            }

        }

        describe("trackable") {
            struct MockTrackable: Trackable {
                var auth0ClientInfo: Auth0ClientInfo
            }

            var trackable: Trackable!

            beforeEach {
                trackable = MockTrackable(auth0ClientInfo: auth0ClientInfo)
            }

            it("should toggle auth0ClientInfo") {
                trackable.tracking(enabled: false)
                expect(trackable.auth0ClientInfo.enabled) == false
                trackable.tracking(enabled: true)
                expect(trackable.auth0ClientInfo.enabled) == true
            }

            it("should mark it as used inside other library") {
                let info = trackable.auth0ClientInfo.info
                trackable.using(inLibrary: "Lock.swift", version: "2.0.0-alpha.0")
                expect(trackable.auth0ClientInfo.info) != info
            }
        }

    }

}
