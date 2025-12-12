import Foundation

/// Internal utility for synchronizing operations across CredentialsManager instances
/// and the Authentication API client. This ensures that only one operation is
/// in flight at a time, preventing concurrency issues when Refresh Token Rotation is enabled.
final class SynchronizationBarrier {
    
    /// Shared singleton instance used by both CredentialsManager and Auth0Authentication
    static let shared = SynchronizationBarrier()
    
    /// Serial dispatch queue for synchronizing operations
    private let dispatchQueue = DispatchQueue(label: "com.auth0.synchronization.serial")
    
    /// Dispatch group for tracking in-flight requests
    private let dispatchGroup = DispatchGroup()
    
    /// Thread-local storage key for tracking if we're already inside the barrier
    private let isInsideBarrierKey = DispatchSpecificKey<Bool>()
    
    private init() {
        // Set up dispatch queue context to track when we're inside the barrier
        dispatchQueue.setSpecific(key: isInsideBarrierKey, value: true)
    }
    
    /// Checks if the current execution context is already inside the barrier
    var isInsideBarrier: Bool {
        return DispatchQueue.getSpecific(key: isInsideBarrierKey) == true
    }
    
    /// Executes an operation in a thread-safe manner.
    /// Only one operation will be executed at a time across all instances.
    /// This method is reentrant - if called from within an existing barrier context,
    /// it will execute immediately without blocking.
    ///
    /// - Parameter operation: The operation to execute. The operation will be run
    ///   on a background queue, but the serial queue ensures only one operation runs at a time.
    ///   The operation must call the completion handler when finished.
    /// - Parameter completion: Completion handler to call when the operation finishes. This will
    ///   be called on the serial queue to maintain ordering.
    func execute(_ operation: @escaping (@escaping () -> Void) -> Void) {
        // If we're already inside the barrier (reentrant call), execute immediately
        if isInsideBarrier {
            operation {}
            return
        }
        
        self.dispatchQueue.async { [dispatchGroup] in
            dispatchGroup.enter()
            
            DispatchQueue.global(qos: .userInitiated).async {
                operation {
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.wait()
        }
    }
}
