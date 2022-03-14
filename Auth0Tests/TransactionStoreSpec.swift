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
