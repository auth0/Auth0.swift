#if WEB_AUTH_PLATFORM
public protocol WebAuthUserAgent {

    func start()
    func cancel()
    func wrap<T>(callback: @escaping (WebAuthResult<T>) -> Void) -> (WebAuthResult<T>) -> Void

}

public extension WebAuthUserAgent {

    func cancel() {}

    func wrap<T>(callback: @escaping (WebAuthResult<T>) -> Void) -> (WebAuthResult<T>) -> Void {
        return callback
    }

}
#endif
