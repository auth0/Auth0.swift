import Foundation
@testable import Auth0

/// Collects what a `DefaultLogger` writes so a test can inspect it.
final class CapturingOutput: LoggerOutput, @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [String] = []

    var text: String {
        lock.lock()
        defer { lock.unlock() }
        return messages.joined(separator: "\n")
    }

    func log(message: String) {
        lock.lock()
        messages.append(message)
        lock.unlock()
    }

    func newLine() {
        log(message: "")
    }

    /// Waits until the asynchronous logger has written `fragment`, for up to two seconds.
    func waitUntilLogged(_ fragment: String) async {
        for _ in 0..<100 where !text.contains(fragment) {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}
