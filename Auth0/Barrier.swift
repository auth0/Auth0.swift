import Foundation

protocol Barrier: AnyObject {
    func raise() -> Bool
    func lower()
}

final class QueueBarrier: Barrier {
    static let shared = QueueBarrier()

    private(set) var isRaised: Bool = false

    private init() {}

    func raise() -> Bool {
        serialQueue.sync {
            guard !self.isRaised else { return false }
            self.isRaised = true
            return self.isRaised
        }
    }

    func lower() {
        serialQueue.sync {
            self.isRaised = false
        }
    }
}
