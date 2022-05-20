import Foundation

@testable import Auth0

struct MockUserAgent: WebAuthUserAgent {

    func start() {}

    func finish() -> (WebAuthResult<Void>) -> Void {
        return { _ in }
    }

}

struct MockGrant: OAuth2Grant {

    var defaults: [String:String] = [:]

    func credentials(from values: [String : String], callback: @escaping (WebAuthResult<Credentials>) -> Void) {
        callback(.success(Credentials()))
    }

    func values(fromComponents components: URLComponents) -> [String : String] {
        var items = components.fragmentValues
        components.queryValues.forEach { items[$0] = $1 }
        return items
    }

}

class SpyTransaction: AuthTransaction {

    var state: String? = nil
    var isCancelled = false
    var isResumed = false

    func cancel() {
        self.isCancelled = true
    }

    func resume(_ url: URL) -> Bool {
        return self.isResumed
    }

}

#if os(iOS)
import UIKit
import SafariServices

class SpyViewController: UIViewController {

    var presented: UIViewController? = nil

    override var presentedViewController: UIViewController? {
        return presented ?? super.presentedViewController
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        completion?()
    }

}

class SpySafariViewController: SFSafariViewController {

    var isPresented = false

    override func present(_ viewControllerToPresent: UIViewController,
                          animated flag: Bool,
                          completion: (() -> Void)? = nil) {
        self.isPresented = true
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        completion?()
    }

}
#endif
