import Foundation
import Combine

public protocol Requestable<ResultType, ErrorType> {
    associatedtype ResultType
    associatedtype ErrorType: Auth0APIError
    func start(_ callback: @escaping (Result<ResultType, ErrorType>) -> Void)
    func parameters(_ extraParameters: [String: Any]) -> any Requestable<ResultType, ErrorType>
    func headers(_ extraHeaders: [String: String]) -> any Requestable<ResultType, ErrorType>
    func requestValidators(_ extraValidators: [RequestValidator]) -> any Requestable<ResultType, ErrorType>
    func start() -> AnyPublisher<ResultType, ErrorType>
    func start() async throws -> ResultType
}

extension Requestable {
    var dpop: DPoP? { (self as? Request<ResultType, ErrorType>)?.dpop }
}

// MARK: - Combine

public extension Requestable {
    func start() -> AnyPublisher<ResultType, ErrorType> {
        return Deferred { Future(self.start) }.eraseToAnyPublisher()
    }
}

// MARK: - Async/Await

public extension Requestable {
    func start() async throws -> ResultType {
        return try await withCheckedThrowingContinuation { continuation in
            self.start { result in
                continuation.resume(with: result)
            }
        }
    }
}
