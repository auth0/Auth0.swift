import Foundation
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

            var subject: [String: Any] {
                return Telemetry.versionInformation(bundle: bundle)
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
                #else
                expect(env["unknown"]).toNot(beNil())
                #endif
            }

        }

        describe("wrapping") {

            var telemetry = Telemetry()
            let version = Telemetry.versionInformation()["version"] ?? Telemetry.NoVersion

            beforeEach {
                telemetry.wrapped(inLibrary: "Lock.iOS", version: "1.0.0-alpha.4")
            }

            it("should have a valid base64 value") {
                expect(telemetry.value).to(beURLSafeBase64())
            }

            it("should have correct info") {
                let value = telemetry.value!
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
                #else
                expect(env["unknown"]).toNot(beNil())
                #endif
            }

        }

        describe("telemetry header") {

            var telemetry = Telemetry()

            it("should set telemetry header") {
                let request = NSMutableURLRequest()
                telemetry.addTelemetryHeader(request: request)
                expect(request.value(forHTTPHeaderField: "Auth0-Client")) == telemetry.value
            }

            it("should not set telemetry header when disabled") {
                let request = NSMutableURLRequest()
                telemetry.enabled = false
                telemetry.addTelemetryHeader(request: request)
                expect(request.value(forHTTPHeaderField: "Auth0-Client")).to(beNil())
            }

        }

        describe("telemetry query item") {

            var telemetry: Telemetry!

            beforeEach {
                telemetry = Telemetry()
            }

            it("should set telemetry header") {
                let items = telemetry.queryItemsWithTelemetry(queryItems: [])
                expect(items.first) == URLQueryItem(name: "auth0Client", value: telemetry.value)
            }

            it("should not set telemetry header when disabled") {
                telemetry.enabled = false
                let items = telemetry.queryItemsWithTelemetry(queryItems: [])
                expect(items).to(beEmpty())
            }

            it("should keep items already in list when adding item") {
                let item = URLQueryItem(name: "key", value: "value")
                let items = telemetry.queryItemsWithTelemetry(queryItems: [item])
                expect(items).to(contain(URLQueryItem(name: "auth0Client", value: telemetry.value)))
                expect(items).to(contain(item))
            }

            it("should keep items already in list when skipping telemetry") {
                telemetry.enabled = false
                let item = URLQueryItem(name: "key", value: "value")
                let items = telemetry.queryItemsWithTelemetry(queryItems: [item])
                expect(items).toNot(contain(URLQueryItem(name: "auth0Client", value: telemetry.value)))
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
                trackable.using(inLibrary: "Lock.swift", version: "2.0.0-alpha.0")
                expect(trackable.telemetry.info) != info
            }
        }

    }

}

class MockedBundle: Bundle {

    var version: String? = nil

    override var infoDictionary: [String : Any]? {
        if let version = self.version {
            return [
                "CFBundleShortVersionString": version
            ]
        }
        return nil
    }
}
