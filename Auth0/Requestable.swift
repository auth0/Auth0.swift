import Foundation
import Combine

public protocol Requestable {
    associatedtype ResultType
    associatedtype ErrorType: Auth0APIError

    func start() async throws -> ResultType
    func start() -> AnyPublisher<ResultType, ErrorType>
    func start(_ callback: @escaping (Result<ResultType, ErrorType>) -> Void)
}
