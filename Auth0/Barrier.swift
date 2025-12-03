import Foundation

protocol Barrier: Sendable {
    func raise() async -> Bool
    func lower() async
}

actor QueueBarrier: Barrier {
    static let shared = QueueBarrier()

    private(set) var isRaised: Bool = false

    private init() {}

    func raise() -> Bool {
        guard !self.isRaised else { return false }
        self.isRaised = true
        return self.isRaised
    }

    func lower() {
        self.isRaised = false
    }
}
