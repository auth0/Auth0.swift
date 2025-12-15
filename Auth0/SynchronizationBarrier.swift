import Foundation

/// Internal utility for synchronizing operations across CredentialsManager instances
/// and the Authentication API client. This ensures that only one operation is
/// in flight at a time, preventing concurrency issues when Refresh Token Rotation is enabled.
///
/// The barrier uses a serial queue to maintain operation ordering and a queue-based system
/// to ensure each operation completes before the next one begins, without using dispatch groups
/// or semaphores that would block threads.
final class SynchronizationBarrier {

    /// Shared singleton instance used by both CredentialsManager and Auth0Authentication
    static let shared = SynchronizationBarrier()

    /// Serial dispatch queue for coordinating operations
    private let queue = DispatchQueue(label: "com.auth0.synchronization.serial")
    
    /// Queue of pending operations waiting to be executed
    private var pendingOperations: [(@escaping () -> Void) -> Void] = []
    
    /// Flag indicating whether an operation is currently executing
    private var isExecuting = false



    /// Executes an operation in a thread-safe manner.
    /// Only one operation will be executed at a time across all instances.
    /// This method is reentrant - if called from within an existing barrier context,
    /// it will execute immediately without blocking.
    ///
    /// The implementation uses a serial queue to coordinate operations without blocking threads.
    /// Operations are queued and executed sequentially. Each operation must call its completion
    /// handler to signal that it has finished, allowing the next operation to proceed.
    ///
    /// - Parameter operation: The operation to execute. The operation will receive a completion
    ///   handler that it **must** call when finished. The completion handler can be called from
    ///   any thread. Operations are executed one at a time in the order they were submitted.
    func execute(_ operation: @escaping (@escaping () -> Void) -> Void) {

        queue.async { [weak self] in
            guard let self = self else { return }

            self.pendingOperations.append(operation)
            self.tryExecuteNext()
        }
    }

    private func tryExecuteNext() {
        guard !isExecuting, !pendingOperations.isEmpty else { return }

        isExecuting = true
        let operation = pendingOperations.removeFirst()

        // Run operation
        operation { [weak self] in
            guard let self = self else { return }

            self.queue.async {
                self.isExecuting = false
                self.tryExecuteNext()
            }
        }
    }
}
