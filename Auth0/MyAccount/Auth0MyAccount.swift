import Foundation

struct Auth0MyAccount: MyAccount {

    let url: URL
    let session: URLSession
    let token: String

    var telemetry: Telemetry
    var logger: Logger?

    var authenticationMethods: MyAccountAuthenticationMethods {
        return Auth0AuthenticationMethods(url: self.url,
                                          session: self.session,
                                          token: self.token,
                                          telemetry: self.telemetry,
                                          logger: self.logger)
    }

    init(token: String,
         url: URL,
         session: URLSession = .shared,
         telemetry: Telemetry = Telemetry(),
         logger: Logger? = nil) {
        self.url = url.appending("me/\(Self.apiVersion)")
        self.session = session
        self.token = token
        self.telemetry = telemetry
        self.logger = logger
    }

}
