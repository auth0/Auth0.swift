import Foundation
import Combine

public protocol Requestable<ResultType, ErrorType>: Sendable {
    associatedtype ResultType
    associatedtype ErrorType: Auth0APIError
    func parameters(_ extraParameters: [String: Any]) -> any Requestable<ResultType, ErrorType>
    func headers(_ extraHeaders: [String: String]) -> any Requestable<ResultType, ErrorType>
    func requestValidators(_ extraValidators: [RequestValidator]) -> any Requestable<ResultType, ErrorType>
    func start(_ callback: @escaping @MainActor (Result<ResultType, ErrorType>) -> Void)
    func start() -> AnyPublisher<ResultType, ErrorType>
    func start() async throws -> ResultType
}

extension Requestable {
    func parameters(_ extraParameters: [String: Any]) -> any Requestable<ResultType, ErrorType> {
        self
    }
    
    func headers(_ extraHeaders: [String: String]) -> any Requestable<ResultType, ErrorType> {
        self
    }
    
    func requestValidators(_ extraValidators: [RequestValidator]) -> any Requestable<ResultType, ErrorType> {
        self
    }
}


// MARK: - Combine

public extension Requestable {

    /**
     Combine publisher for the request.

     - Returns: A type-erased publisher.
     */
    func start() -> AnyPublisher<ResultType, ErrorType> {
        return Deferred { Future { [self] promise in
            let box = SendableBox(value: promise)
            self.start { result in box.value(result) }
        } }.eraseToAnyPublisher()
    }

}

// MARK: - Async/Await

#if canImport(_Concurrency)
public extension Requestable {

    /**
     Performs the request.

     - Throws: An error that conforms to ``Auth0APIError``.
     */
    func start() async throws -> ResultType {
        return try await withCheckedThrowingContinuation { continuation in
            self.start { result in
                continuation.resume(with: result)
            }
        }
    }

}
#endif
