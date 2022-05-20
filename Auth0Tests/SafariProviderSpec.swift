#if os(iOS)
import UIKit
import SafariServices
import Quick
import Nimble

@testable import Auth0

private let Url = URL(string: "https://auth0.com")!
private let Timeout: DispatchTimeInterval = .seconds(2)

class SafariProviderSpec: QuickSpec {

    override func spec() {

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
            var safari: SFSafariViewController!

            beforeEach {
                root = SpyViewController()
                safari = SFSafariViewController(url: Url)
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

        }

        describe("user agent") {

            it("should present the safari view controller") {
                let root = SpyViewController()
                UIApplication.shared.keyWindow?.rootViewController = root
                let safari = SpySafariViewController(url: Url)
                let userAgent = SafariUserAgent(controller: safari, callback: { _ in })
                root.presented = safari
                userAgent.start()
                expect(safari.isPresented) == true
            }

            it("should call the callback with an error") {
                let safari = SFSafariViewController(url: Url)

                waitUntil(timeout: Timeout) { done in
                    let userAgent = SafariUserAgent(controller: safari, callback: { result in
                        expect(result).to(beFailure())
                        done()
                    })
                    let callback = userAgent.finish()
                    callback(.failure(.userCancelled))
                }
            }

        }

    }

}
#endif
