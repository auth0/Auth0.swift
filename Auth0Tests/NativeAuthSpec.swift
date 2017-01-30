// NativeAuthSpec.swift
//
// Copyright (c) 2017 Auth0 (http://auth0.com)
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
import SafariServices
import OHHTTPStubs

@testable import Auth0

private let ClientId = "CLIENT_ID"
private let Domain = "samples.auth0.com"
private let DomainURL = URL(fileURLWithPath: Domain)

private let AccessToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let IdToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let FacebookToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
private let InvalidFacebookToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")

class MockNativeAuthTransaction: NativeAuthTransaction {
    var connection: String = "facebook"
    var scope: String = "openid"
    var parameters: [String : Any] = [:]

    var nativeError: Bool = false

    var delayed: NativeAuthTransaction.Callback = { _ in }

    func auth(callback: @escaping NativeAuthTransaction.Callback) {
        self.delayed = callback
    }

    func cancel() {
        self.delayed(.failure(error: WebAuthError.userCancelled))
        self.delayed = { _ in }
    }

    func resume(_ url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        guard !self.nativeError else {
            self.cancel()
            return false
        }
        self.delayed(.success(result: NativeAuthCredentials(token: FacebookToken, extras: [:])))
        self.delayed = { _ in }
        return true
    }

    public func start(callback: @escaping (Result<Credentials>) -> ()) {
        TransactionStore.shared.store(self)
        self.auth { result in
            switch result {
            case .success(_):
                callback(.success(result: Credentials(accessToken: FacebookToken)))
            case .failure(let error):
                callback(.failure(error: error))
            }
        }
    }
}

class NativeAuthSpec: QuickSpec {

    override func spec() {

        var nativeTransaction: MockNativeAuthTransaction!
        var error: Error?
        var nativeCredentials: NativeAuthCredentials!

        beforeEach {
            error = nil
            nativeCredentials = nil
            nativeTransaction = MockNativeAuthTransaction()
            nativeTransaction.auth { result in
                switch result {
                case .success(let credentials):
                    nativeCredentials = credentials
                case .failure(let nativeError):
                    error = nativeError
                }
            }
        }


        describe("Default values set") {

            it("should have connection") {
                expect(nativeTransaction.connection) == "facebook"
            }

            it("should have scope") {
                expect(nativeTransaction.scope) == "openid"
            }

            it("should have parameters") {
                expect(nativeTransaction.parameters).to(haveCount(0))
            }
        }

        describe("auth") {

            it("should store transaction in store") {
                nativeTransaction.start { _ in }
                expect(TransactionStore.shared.current?.state) == nativeTransaction.state
            }

            it("should return credentials on success") {
                nativeTransaction.start { result in
                    expect(result).to(haveCredentials())
                }
                _ = nativeTransaction.resume(DomainURL, options: [:])
            }
        }

        describe("resume") {

            it("should return true") {
                expect(nativeTransaction.resume(DomainURL, options: [:])) == true
            }

            it("should return native credentials") {
                _ = nativeTransaction.resume(DomainURL, options: [:])
                expect(error).to(beNil())
                expect(nativeCredentials!.token) == FacebookToken
            }

            it("should return false") {
                nativeTransaction.nativeError = true
                expect(nativeTransaction.resume(DomainURL, options: [:])) == false
            }

            it("should return error") {
                nativeTransaction.nativeError = true
                _ = nativeTransaction.resume(DomainURL, options: [:])
                expect(error).toNot(beNil())
            }
        }
        
    }
    
}



