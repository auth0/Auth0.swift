import Foundation

protocol Barrier: AnyObject {
    func raise() -> Bool
    func lower()
}

final class QueueBarrier: Barrier {
    static let shared = QueueBarrier()

    private let queue = DispatchQueue(label: "com.auth0.webauth.barrier.serial")
    private(set) var isRaised: Bool = false

    private init() {}

    func raise() -> Bool {
        self.queue.sync {
            guard !self.isRaised else { return false }
            self.isRaised = true
            return self.isRaised
        }
    }

    func lower() {
        self.queue.sync {
            self.isRaised = false
        }
    }
}
