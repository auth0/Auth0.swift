import Foundation
import Quick
import Nimble

@testable import Auth0

class PARUtilsSpec: QuickSpec {

    override class func spec() {
        let clientId = "ClientId"
        let domain = "samples.auth0.com"
        let baseURL = URL.httpsURL(from: domain)

        describe("isValidRequestUri") {
            it("should return true for valid request_uri") {
                let uri = "urn:ietf:params:oauth:request_uri:abc123"
                expect(PARUtils.isValidRequestUri(uri)) == true
            }

            it("should return true for request_uri with special characters") {
                let uri = "urn:ietf:params:oauth:request_uri:some-complex/uri_value.with"
                expect(PARUtils.isValidRequestUri(uri)) == true
            }

            it("should return false for empty string") {
                expect(PARUtils.isValidRequestUri("")) == false
            }

            it("should return false for uri without correct prefix") {
                expect(PARUtils.isValidRequestUri("urn:ietf:params:oauth:request:abc123")) == false
            }

            it("should return false for arbitrary string") {
                expect(PARUtils.isValidRequestUri("https://example.com/some-uri")) == false
            }

            it("should return false for partial prefix") {
                expect(PARUtils.isValidRequestUri("urn:ietf:params:oauth:request_uri")) == false
            }
        }

        describe("buildAuthorizeURL") {
            it("should build URL with client_id and request_uri") {
                let requestUri = "urn:ietf:params:oauth:request_uri:abc123"
                let url = PARUtils.buildAuthorizeURL(baseURL: baseURL,
                                                     clientId: clientId,
                                                     requestUri: requestUri)
                let components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                expect(components.scheme) == "https"
                expect(components.host) == domain
                expect(components.path) == "/authorize"
                expect(components.queryItems).to(containItem(withName: "client_id", value: clientId))
                expect(components.queryItems).to(containItem(withName: "request_uri", value: requestUri))
            }

            it("should include additional parameters") {
                let requestUri = "urn:ietf:params:oauth:request_uri:abc123"
                let url = PARUtils.buildAuthorizeURL(baseURL: baseURL,
                                                     clientId: clientId,
                                                     requestUri: requestUri,
                                                     additionalParameters: ["session_transfer_token": "sst_value",
                                                                            "custom_param": "custom_value"])
                let components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                expect(components.queryItems).to(containItem(withName: "session_transfer_token", value: "sst_value"))
                expect(components.queryItems).to(containItem(withName: "custom_param", value: "custom_value"))
            }

            it("should not include additional parameters when map is empty") {
                let requestUri = "urn:ietf:params:oauth:request_uri:abc123"
                let url = PARUtils.buildAuthorizeURL(baseURL: baseURL,
                                                     clientId: clientId,
                                                     requestUri: requestUri,
                                                     additionalParameters: [:])
                let components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                expect(components.queryItems?.count) == 2
            }
        }
    }

}
