import Foundation

struct Auth0MyAccount: MyAccount {

    let url: URL
    let session: URLSession
    let token: String

    var telemetry: Telemetry
    var logger: Logger?

    let authenticationMethods: MyAccountAuthenticationMethods

    init(token: String,
         url: URL,
         session: URLSession = .shared,
         telemetry: Telemetry = Telemetry(),
         logger: Logger? = nil) {
        self.url = URL(string: "me/\(Self.apiVersion)", relativeTo: url)!
        self.session = session
        self.token = token
        self.telemetry = telemetry
        self.logger = logger

        self.authenticationMethods = Auth0AuthenticationMethods(url: self.url,
                                                                session: session,
                                                                token: token,
                                                                telemetry: telemetry,
                                                                logger: logger)
    }

}
