#if os(iOS)
import Foundation
import UIKit
import SafariServices
import Quick
import Nimble

@testable import Auth0

private let RedirectURL = URL(string: "https://samples.auth0.com/callback")!
private let Timeout: NimbleTimeInterval = .seconds(2)

class SafariProviderSpec: QuickSpec {

    override class func spec() {

        var safari: SFSafariViewController!
        var userAgent: SafariUserAgent!

        beforeEach {
            safari = SFSafariViewController(url: RedirectURL)
            userAgent = SafariUserAgent(controller: safari, callback: { _ in })
        }

        describe("WebAuthentication extension") {

            it("should create a safari provider") {
                let provider = WebAuthentication.safariProvider()
                expect(provider(RedirectURL, { _ in })).to(beAKindOf(SafariUserAgent.self))
            }

            it("should use the fullscreen presentation style by default") {
                let provider = WebAuthentication.safariProvider()
                let userAgent = provider(RedirectURL, { _ in }) as! SafariUserAgent
                expect(userAgent.controller.modalPresentationStyle) == .fullScreen
            }

            it("should set a custom presentation style") {
                let style = UIModalPresentationStyle.formSheet
                let provider = WebAuthentication.safariProvider(style: style)
                let userAgent = provider(RedirectURL, { _ in }) as! SafariUserAgent
                expect(userAgent.controller.modalPresentationStyle) == style
            }

            it("should use the cancel dismiss button style") {
                let provider = WebAuthentication.safariProvider()
                let userAgent = provider(RedirectURL, { _ in }) as! SafariUserAgent
                expect(userAgent.controller.dismissButtonStyle) == .cancel
            }

        }

        describe("user agent") {

            it("should have a custom description") {
                let safari = SFSafariViewController(url: RedirectURL)
                let userAgent = SafariUserAgent(controller: safari, callback: { _ in })
                expect(userAgent.description) == "SFSafariViewController"
            }

            it("should be the safari view controller's delegate") {
                expect(safari.delegate).to(be(userAgent))
            }

            it("should be the safari view controller's presentation delegate") {
                expect(safari.presentationController?.delegate).to(be(userAgent))
            }

            it("should present the safari view controller") {
                let root = SpyViewController()
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = root
                let safari = SpySafariViewController(url: RedirectURL)
                userAgent = SafariUserAgent(controller: safari, callback: { _ in })
                root.presented = safari
                userAgent.start()
                expect(safari.isPresented) == true
            }

            it("should call the callback with an error when the user cancels the operation") {
                waitUntil(timeout: Timeout) { done in
                    DispatchQueue.main.async { [safari] in
                        let userAgent = SafariUserAgent(controller: safari!, callback: { result in
                            expect(result).to(haveWebAuthError(WebAuthError(code: .userCancelled)))
                            done()
                        })
                        userAgent.finish(with: .failure(.userCancelled))
                    }
                }
            }

            it("should call the callback with an error when the safari view controller cannot be dismissed") {
                let expectedError = WebAuthError(code: .unknown("Cannot dismiss SFSafariViewController"))

               waitUntil(timeout: Timeout) { done in
                    DispatchQueue.main.async { [safari] in
                        let userAgent = SafariUserAgent(controller: safari!, callback: { result in
                            expect(result).to(haveWebAuthError(expectedError))
                            done()
                        })
                        userAgent.finish(with: .success(()))
                    }
                }
            }

            it("should call the callback with success") {
                let root = UIViewController()
                let window = UIWindow(frame: CGRect())
                window.rootViewController = root
                window.makeKeyAndVisible()
                root.present(safari, animated: false)

                waitUntil(timeout: Timeout) { done in
                    DispatchQueue.main.async { [safari] in
                        let userAgent = SafariUserAgent(controller: safari!, callback: { result in
                            expect(result).to(beSuccessful())
                            done()
                        })
                        userAgent.finish(with: .success(()))
                    }
                }
            }

            it("should cancel the transaction when the user cancels the operation") {
                let transaction = SpyTransaction()
                TransactionStore.shared.store(transaction)
                userAgent.safariViewControllerDidFinish(safari)
                expect(transaction.isCancelled) == true
            }

            it("should cancel the transaction when the user dismisses the safari view controller") {
                let transaction = SpyTransaction()
                TransactionStore.shared.store(transaction)
                userAgent.presentationControllerDidDismiss(safari.presentationController!)
                expect(transaction.isCancelled) == true
            }

        }

    }

}
#endif
