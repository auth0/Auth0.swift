// TransactionStoreSpec.swift
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

import Foundation
import Quick
import Nimble

@testable import Auth0

class TransactionStoreSpec: QuickSpec {

    override func spec() {

        var storage: TransactionStore!
        var session: MockSession!

        beforeEach {
            storage = TransactionStore()
            session = MockSession()
        }

        describe("storage") {


            it("should store session") {
                storage.store(session)
            }

            it("should cancel current") {
                storage.store(session)
                storage.store(MockSession())
                expect(session.cancelled) == true
            }

            it("should clear session") {
                storage.store(session)
                storage.clear()
                expect(storage.current).to(beNil())
            }
        }

        describe("cancel") {

            it("should be noop when there is no current session") {
                session.cancel()
            }

            it("should cancel current") {
                storage.store(session)
                storage.cancel(session)
                expect(session.cancelled) == true
            }

            it("should cancel if matches current via state") {
                session.state = "1"
                let other = MockSession()
                other.state = "2"
                storage.store(session)
                storage.cancel(other)
                expect(session.cancelled) == false
                expect(other.cancelled) == true
            }

        }

        describe("resume") {

            let url = URL(string: "https://auth0.com")!

            beforeEach {
                storage.store(session)
                session.resumeResult = true
            }

            it("should resume current") {
                expect(storage.resume(url)) == true
            }

            it("should return default when no current is available") {
                storage.cancel(session)
                expect(storage.resume(url)) == false
            }

        }
    }

}

class MockSession: AuthTransaction {

    var state: String? = nil

    var cancelled = false
    var resumeResult = false

    func cancel() {
        self.cancelled = true
    }

    func resume(_ url: URL) -> Bool {
        return self.resumeResult
    }

}
