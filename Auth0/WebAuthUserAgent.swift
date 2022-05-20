#if WEB_AUTH_PLATFORM
public protocol WebAuthUserAgent {

    func start()
    func finish() -> (WebAuthResult<Void>) -> Void

}
#endif
