import Testing
import Foundation
@testable import Auth0

@Suite
struct EmbeddedAuthErrorTests {

    // MARK: - init(info:statusCode:)

    @Test func readsErrorCodeFromErrorKey() {
        let error = EmbeddedAuthError(info: ["error": "invalid_request", "error_description": "bad input"], statusCode: 400)
        #expect(error.code == "invalid_request")
    }

    @Test func fallsBackToUnknownWhenErrorKeyAbsent() {
        let error = EmbeddedAuthError(info: [:], statusCode: 400)
        #expect(error.code == unknownError)
    }

    @Test func storesStatusCode() {
        let error = EmbeddedAuthError(info: ["error": "invalid_client"], statusCode: 401)
        #expect(error.statusCode == 401)
    }

    @Test func storesRawInfo() {
        let error = EmbeddedAuthError(info: ["error": "server_error", "error_description": "oops"], statusCode: 500)
        #expect(error.info["error"] as? String == "server_error")
    }

    // MARK: - debugDescription

    @Test func debugDescriptionContainsErrorCode() {
        let error = EmbeddedAuthError(info: ["error": "invalid_client", "error_description": "Unknown client"], statusCode: 401)
        #expect(error.debugDescription.contains("invalid_client"))
    }

    // MARK: - Equatable

    @Test func equalsAnotherErrorWithSameCodeAndStatus() {
        let a = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 400)
        let b = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 400)
        #expect(a == b)
    }

    @Test func differsWhenStatusCodesDiffer() {
        let a = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 400)
        let b = EmbeddedAuthError(info: ["error": "invalid_request"], statusCode: 401)
        #expect(a != b)
    }
}
