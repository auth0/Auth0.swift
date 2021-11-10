import Foundation

protocol Requestable {
    associatedtype ResultType

    func start(_ callback: @escaping (Auth0Result<ResultType>) -> Void)
}
