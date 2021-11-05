#if WEB_AUTH_PLATFORM
protocol AuthSession {

    func start() -> Bool
    func cancel()

}
#endif
