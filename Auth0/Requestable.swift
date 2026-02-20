import Foundation

public protocol Requestable<ResultType, ErrorType> {
    associatedtype ResultType
    associatedtype ErrorType: Auth0APIError
    func start(_ callback: @escaping (Result<ResultType, ErrorType>) -> Void)
    func parameters(_ extraParameters: [String: Any]) -> any Requestable<ResultType, ErrorType>
    func headers(_ extraHeaders: [String: String]) -> any Requestable<ResultType, ErrorType>
    func requestValidators(_ extraValidators: [RequestValidator]) -> any Requestable<ResultType, ErrorType>
}
