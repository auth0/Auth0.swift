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

    override func spec() {

        var safari: SFSafariViewController!
        var userAgent: SafariUserAgent!

        beforeEach { @MainActor in
            safari = SFSafariViewController(url: RedirectURL)
            userAgent = SafariUserAgent(controller: safari, callback: { _ in })
        }

        describe("WebAuthentication extension") {

            it("should create a safari provider") { @MainActor in
                let provider = WebAuthentication.safariProvider()
                expect(provider(RedirectURL, { _ in })).to(beAKindOf(SafariUserAgent.self))
            }

            it("should use the fullscreen presentation style by default") { @MainActor in
                let provider = WebAuthentication.safariProvider()
                let userAgent = provider(RedirectURL, { _ in }) as! SafariUserAgent
                expect(userAgent.controller.modalPresentationStyle) == .fullScreen
            }

            it("should set a custom presentation style") { @MainActor in
                let style = UIModalPresentationStyle.formSheet
                let provider = WebAuthentication.safariProvider(style: style)
                let userAgent = provider(RedirectURL, { _ in }) as! SafariUserAgent
                expect(userAgent.controller.modalPresentationStyle) == style
            }

            it("should use the cancel dismiss button style") { @MainActor in
                let provider = WebAuthentication.safariProvider()
                let userAgent = provider(RedirectURL, { _ in }) as! SafariUserAgent
                expect(userAgent.controller.dismissButtonStyle) == .cancel
            }

        }

        describe("SFSafariViewController extension") {

            var root: SpyViewController!

            beforeEach { @MainActor in
                root = SpyViewController()
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = root
            }

            it("should return nil when root is nil") { @MainActor in
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = nil
                expect(safari.topViewController).to(beNil())
            }

            it("should return root when is top controller") { @MainActor in
                expect(safari.topViewController) == root
            }

            it("should return presented controller") { @MainActor in
                let presented = UIViewController()
                root.presented = presented
                expect(safari.topViewController) == presented
            }

            it("should return split view controller if contains nothing") { @MainActor in
                let split = UISplitViewController()
                root.presented = split
                expect(safari.topViewController) == split
            }

            it("should return last controller from split view controller") { @MainActor in
                let split = UISplitViewController()
                let last = UIViewController()
                split.viewControllers = [UIViewController(), last]
                root.presented = split
                expect(safari.topViewController) == last
            }

            it("should return navigation controller if contains nothing") { @MainActor in
                let navigation = UINavigationController()
                root.presented = navigation
                expect(safari.topViewController) == navigation
            }

            it("should return top from navigation controller") { @MainActor in
                let top = UIViewController()
                let navigation = UINavigationController(rootViewController: top)
                root.presented = navigation
                expect(safari.topViewController) == top
            }

            it("should return tab bar controller if contains nothing") { @MainActor in
                let tabs = UITabBarController()
                root.presented = tabs
                expect(safari.topViewController) == tabs
            }

            it("should return top from tab bar controller") { @MainActor in
                let top = UIViewController()
                let tabs = UITabBarController()
                tabs.viewControllers = [top]
                root.presented = tabs
                expect(safari.topViewController) == top
            }
        }

        describe("user agent") {

            it("should have a custom description") { @MainActor in
                let safari = SFSafariViewController(url: RedirectURL)
                let userAgent = SafariUserAgent(controller: safari, callback: { _ in })
                expect(userAgent.description) == "SFSafariViewController"
            }

            it("should be the safari view controller's delegate") { @MainActor in
                expect(safari.delegate).to(be(userAgent))
            }

            it("should be the safari view controller's presentation delegate") { @MainActor in
                expect(safari.presentationController?.delegate).to(be(userAgent))
            }

            it("should present the safari view controller") { @MainActor in
                let root = SpyViewController()
                UIApplication.shared.windows.last(where: \.isKeyWindow)?.rootViewController = root
                let safari = SpySafariViewController(url: RedirectURL)
                userAgent = SafariUserAgent(controller: safari, callback: { _ in })
                root.presented = safari
                userAgent.start()
                expect(safari.isPresented) == true
            }

            it("should call the callback with an error when the user cancels the operation") {
                await waitUntil(timeout: Timeout) { done in
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

                await waitUntil(timeout: Timeout) { done in
                    DispatchQueue.main.async { [safari] in
                        let userAgent = SafariUserAgent(controller: safari!, callback: { result in
                            expect(result).to(haveWebAuthError(expectedError))
                            done()
                        })
                        userAgent.finish(with: .success(()))
                    }
                }
            }

            it("should call the callback with success") { @MainActor in
                let root = UIViewController()
                let window = UIWindow(frame: CGRect())
                window.rootViewController = root
                window.makeKeyAndVisible()
                root.present(safari, animated: false)

                await waitUntil(timeout: Timeout) { done in
                    DispatchQueue.main.async { [safari] in
                        let userAgent = SafariUserAgent(controller: safari!, callback: { result in
                            expect(result).to(beSuccessful())
                            done()
                        })
                        userAgent.finish(with: .success(()))
                    }
                }
            }

            it("should cancel the transaction when the user cancels the operation") { @MainActor in
                let transaction = SpyTransaction()
                TransactionStore.shared.store(transaction)
                userAgent.safariViewControllerDidFinish(safari)
                expect(transaction.isCancelled) == true
            }

            it("should cancel the transaction when the user dismisses the safari view controller") { @MainActor in
                let transaction = SpyTransaction()
                TransactionStore.shared.store(transaction)
                userAgent.presentationControllerDidDismiss(safari.presentationController!)
                expect(transaction.isCancelled) == true
            }

        }

    }

}
#endif
