import Foundation

struct Auth0MyAccount: MyAccount {

    let url: URL
    let session: URLSession
    let token: String

    var auth0ClientInfo: Auth0ClientInfo
    var logger: Logger?
    var dpop: DPoP?

    static let apiVersion = "v1"

    var authenticationMethods: MyAccountAuthenticationMethods {
        return Auth0MyAccountAuthenticationMethods(token: self.token,
                                                   url: self.url,
                                                   session: self.session,
                                                   auth0ClientInfo: self.auth0ClientInfo,
                                                   logger: self.logger,
                                                   dpop: self.dpop)
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

    // MARK: - Profile

    func getUserProfile(options: GetUserProfileOptions?) -> any Requestable<MyAccountProfile, MyAccountError> {
        var parameters: [String: Any] = [:]
        if let fields = options?.fields, !fields.isEmpty {
            parameters["fields"] = fields.joined(separator: ",")
            if let includeFields = options?.includeFields {
                parameters["include_fields"] = includeFields ? "true" : "false"
            }
        }
        return Request(session: session,
                       url: url.appending("profile"),
                       method: "GET",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: parameters,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

    func updateUserProfile(_ request: UpdateUserProfileRequest) -> any Requestable<MyAccountProfile, MyAccountError> {
        return Request(session: session,
                       url: url.appending("profile"),
                       method: "PATCH",
                       handle: { @Sendable result, callback in myAcccountDecodable(result: result, callback: callback) },
                       parameters: request.toPayload,
                       headers: defaultHeaders,
                       logger: logger,
                       auth0ClientInfo: auth0ClientInfo,
                       dpop: self.dpop)
    }

}
