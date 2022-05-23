#if os(iOS)
import Foundation
import UIKit
import SafariServices
import Quick
import Nimble

@testable import Auth0

private let Url = URL(string: "https://auth0.com")!
private let Timeout: DispatchTimeInterval = .seconds(2)

class SafariProviderSpec: QuickSpec {

    override func spec() {

        var safari: SFSafariViewController!
        var userAgent: SafariUserAgent!

        beforeEach {
            safari = SFSafariViewController(url: Url)
            userAgent = SafariUserAgent(controller: safari, callback: { _ in })
        }

        describe("WebAuthentication extension") {

            it("should create a safari provider") {
                let provider = WebAuthentication.safariProvider()
                expect(provider(Url, {_ in })).to(beAKindOf(SafariUserAgent.self))
            }

            it("should use the fullscreen presentation style by default") {
                let userAgent = WebAuthentication.safariProvider()(Url, {_ in }) as! SafariUserAgent
                expect(userAgent.controller.modalPresentationStyle) == .fullScreen
            }

            it("should set a custom presentation style") {
                let style = UIModalPresentationStyle.formSheet
                let userAgent = WebAuthentication.safariProvider(style: style)(Url, {_ in }) as! SafariUserAgent
                expect(userAgent.controller.modalPresentationStyle) == style
            }

            it("should use the cancel dismiss button style") {
                let userAgent = WebAuthentication.safariProvider()(Url, {_ in }) as! SafariUserAgent
                expect(userAgent.controller.dismissButtonStyle) == .cancel
            }

        }

        describe("SFSafariViewController extension") {

            var root: SpyViewController!

            beforeEach {
                root = SpyViewController()
                UIApplication.shared.keyWindow?.rootViewController = root
            }

            it("should return nil when root is nil") {
                UIApplication.shared.keyWindow?.rootViewController = nil
                expect(safari.topViewController).to(beNil())
            }

            it("should return root when is top controller") {
                expect(safari.topViewController) == root
            }

            it("should return presented controller") {
                let presented = UIViewController()
                root.presented = presented
                expect(safari.topViewController) == presented
            }

            it("should return split view controller if contains nothing") {
                let split = UISplitViewController()
                root.presented = split
                expect(safari.topViewController) == split
            }

            it("should return last controller from split view controller") {
                let split = UISplitViewController()
                let last = UIViewController()
                split.viewControllers = [UIViewController(), last]
                root.presented = split
                expect(safari.topViewController) == last
            }

            it("should return navigation controller if contains nothing") {
                let navigation = UINavigationController()
                root.presented = navigation
                expect(safari.topViewController) == navigation
            }

            it("should return top from navigation controller") {
                let top = UIViewController()
                let navigation = UINavigationController(rootViewController: top)
                root.presented = navigation
                expect(safari.topViewController) == top
            }

            it("should return tab bar controller if contains nothing") {
                let tabs = UITabBarController()
                root.presented = tabs
                expect(safari.topViewController) == tabs
            }

            it("should return top from tab bar controller") {
                let top = UIViewController()
                let tabs = UITabBarController()
                tabs.viewControllers = [top]
                root.presented = tabs
                expect(safari.topViewController) == top
            }
        }

        describe("user agent") {

            it("should have a custom description") {
                let userAgent = SafariUserAgent(controller: SFSafariViewController(url: Url), callback: { _ in })
                expect(userAgent.description) == "SFSafariViewController"
            }

            it("should be the safari view controller's delegate") {
                expect(safari.delegate).to(be(userAgent))
            }

            it("should present the safari view controller") {
                let root = SpyViewController()
                UIApplication.shared.keyWindow?.rootViewController = root
                let safari = SpySafariViewController(url: Url)
                userAgent = SafariUserAgent(controller: safari, callback: { _ in })
                root.presented = safari
                userAgent.start()
                expect(safari.isPresented) == true
            }

            it("should call the callback with an error when the user cancels the operation") {
                waitUntil(timeout: Timeout) { done in
                    userAgent = SafariUserAgent(controller: safari, callback: { result in
                        expect(result).to(haveWebAuthError(WebAuthError(code: .userCancelled)))
                        done()
                    })
                    let callback = userAgent.finish()
                    callback(.failure(.userCancelled))
                }
            }

            it("should call the callback with an error when the safari view controller cannot be dismissed") {
                let expectedError = WebAuthError(code: .unknown("Cannot dismiss SFSafariViewController"))

                waitUntil(timeout: Timeout) { done in
                    userAgent = SafariUserAgent(controller: safari, callback: { result in
                        expect(result).to(haveWebAuthError(expectedError))
                        done()
                    })
                    let callback = userAgent.finish()
                    callback(.success(()))
                }
            }

            it("should call the callback with success") {
                let root = UIViewController()
                let window = UIWindow(frame: CGRect())
                window.rootViewController = root
                window.makeKeyAndVisible()
                root.present(safari, animated: false)

                waitUntil(timeout: Timeout) { done in
                    userAgent = SafariUserAgent(controller: safari, callback: { result in
                        expect(result).to(beSuccessful())
                        done()
                    })
                    let callback = userAgent.finish()
                    callback(.success(()))
                }
            }

            it("should cancel the transaction when the user cancels the operation") {
                let transaction = SpyTransaction()
                TransactionStore.shared.store(transaction)
                userAgent.safariViewControllerDidFinish(safari)
                expect(transaction.isCancelled) == true
            }

        }

    }

}
#endif
