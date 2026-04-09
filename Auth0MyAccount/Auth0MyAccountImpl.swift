import Foundation
#if SWIFT_PACKAGE
import Auth0
#endif

struct Auth0MyAccountImpl: MyAccount {

    let url: URL
    let session: URLSession
    let token: String

    var auth0ClientInfo: Auth0ClientInfo
    var logger: Logger?

    static let apiVersion = "v1"

    var authenticationMethods: MyAccountAuthenticationMethods {
        return Auth0MyAccountAuthenticationMethodsImpl(token: self.token,
                                                      url: self.url,
                                                      session: self.session,
                                                      auth0ClientInfo: self.auth0ClientInfo,
                                                      logger: self.logger)
    }

    init(token: String,
         url: URL,
         session: URLSession = .shared,
         auth0ClientInfo: Auth0ClientInfo = Auth0ClientInfo(),
         logger: Logger? = nil) {
        self.url = url.appending("me/\(Self.apiVersion)")
        self.session = session
        self.token = token
        self.auth0ClientInfo = auth0ClientInfo
        self.logger = logger
    }

}
