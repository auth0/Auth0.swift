#if WEB_AUTH_PLATFORM
public protocol WebAuthUserAgent {

    func start()
    func finish(with result: WebAuthResult<Void>)

}
#endif
