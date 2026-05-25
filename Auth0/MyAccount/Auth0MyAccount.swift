import Foundation

struct Auth0MyAccount: MyAccount {

    let url: URL
    let session: URLSession
    let token: String

    var telemetry: Telemetry
    var logger: Logger?
    var dpop: DPoP?

    static let apiVersion = "v1"

    var authenticationMethods: MyAccountAuthenticationMethods {
        return Auth0MyAccountAuthenticationMethods(token: self.token,
                                                   url: self.url,
                                                   session: self.session,
                                                   telemetry: self.telemetry,
                                                   logger: self.logger,
                                                   dpop: self.dpop)
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
