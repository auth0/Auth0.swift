import Foundation

protocol Requestable {
    associatedtype ResultType

    func start(_ callback: @escaping (Result<ResultType>) -> Void)
}
