import Foundation

#if swift(<5.0)
/**
 Result object for Auth0 APIs requests

 - Success: request completed successfuly with it's response body
 - Failure: request failed with a specific error
 */
public enum Result<T> {
    case success(T)
    case failure(Error)
}

// Shims for older interface with named parameters
extension Result {
    @available(*, deprecated, renamed: "success(_:)")
    public static func success(result: T) -> Self {
        return .success(result)
    }

    @available(*, deprecated, renamed: "failure(_:)")
    public static func failure(error: Error) -> Self {
        return .failure(error)
    }
}
#else
public typealias Result<T> = Swift.Result<T, Error>

// Shims for older interface with named parameters
extension Result {
    @available(*, deprecated, renamed: "success(_:)")
    public static func success(result: Success) -> Self {
        return .success(result)
    }

    @available(*, deprecated, renamed: "failure(_:)")
    public static func failure(error: Failure) -> Self {
        return .failure(error)
    }
}
#endif
