import Foundation

protocol Requestable {
    associatedtype ResultType
    associatedtype ErrorType: Auth0APIError

    func start(_ callback: @escaping (Result<ResultType, ErrorType>) -> Void)
}
