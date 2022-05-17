#if WEB_AUTH_PLATFORM
public protocol WebAuthUserAgent {

    func start()
    func finish(_ callback: @escaping (WebAuthResult<Void>) -> Void) -> (WebAuthResult<Void>) -> Void

}

public extension WebAuthUserAgent {

    func finish(_ callback: @escaping (WebAuthResult<Void>) -> Void) -> (WebAuthResult<Void>) -> Void {
        return { result in callback(result) }
    }

}
#endif
