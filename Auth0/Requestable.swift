import Foundation

public protocol Requestable {
    associatedtype ResultType
    associatedtype ErrorType: Auth0APIError
    func start(_ callback: @escaping @Sendable (Result<ResultType, ErrorType>) -> Void)
}
