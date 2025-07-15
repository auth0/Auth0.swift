import Foundation

protocol Barrier: Sendable {
    func raise() async -> Bool
    func lower() async
}

actor QueueBarrier: Barrier {
    static let shared = QueueBarrier()

    private let queue = DispatchQueue(label: "com.auth0.webauth.barrier.serial")
    private(set) var isRaised: Bool = false

    private init() {}

    func raise() async -> Bool {
//        self.queue.sync {
            guard !self.isRaised else { return false }
            self.isRaised = true
            return self.isRaised
//        }
    }

    func lower() async {
//        self.queue.sync {
            self.isRaised = false
//        }
    }
}
