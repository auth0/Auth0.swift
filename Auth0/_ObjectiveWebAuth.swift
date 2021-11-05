#if WEB_AUTH_PLATFORM
import Foundation

@objc(A0WebAuth)
/// Web-based Auth with Auth0
// swiftlint:disable:next type_name
public class _ObjectiveOAuth2: NSObject {

    private(set) var webAuth: Auth0WebAuth

    @objc public override init() {
        let values = plistValues(bundle: Bundle.main)!
        self.webAuth = Auth0WebAuth(clientId: values.clientId, url: .a0_url(values.domain))
    }

    @objc public init(clientId: String, url: URL) {
        self.webAuth = Auth0WebAuth(clientId: clientId, url: url)
    }

    @objc public func addParameters(_ parameters: [String: String]) {
        _ = self.webAuth.parameters(parameters)
    }

    /**
     For redirect url instead of a custom scheme it will use `https` and iOS 9 Universal Links.

     Before enabling this flag you'll need to configure Universal Links
    */
    @objc public var universalLink: Bool {
        get {
            return self.webAuth.universalLink
        }
        set {
            self.webAuth.universalLink = newValue
        }
    }

    /**
     Disable Single Sign On (SSO) on iOS 13+ and macOS.

     Has no effect on older versions of iOS.
    */
    @objc public var ephemeralSession: Bool {
        get {
            return self.webAuth.ephemeralSession
        }
        set {
            self.webAuth.ephemeralSession = newValue
        }
    }

    /**
     Specify a connection name to be used to authenticate.

     By default no connection is specified, so the hosted login page will be displayed
    */
    @objc public var connection: String? {
        get {
            return self.webAuth.parameters["connection"]
        }
        set {
            if let value = newValue {
                _ = self.webAuth.connection(value)
            }
        }
    }

    /**
     Scopes that will be requested during auth
    */
    @objc public var scope: String? {
        get {
            return self.webAuth.parameters["scope"]
        }
        set {
            if let value = newValue {
                _ = self.webAuth.scope(value)
            }
        }
    }

    /**
     Starts the web-based auth flow by modally presenting a ViewController in the top-most controller.

     ```
     A0WebAuth *auth = [[A0WebAuth alloc] initWithClientId:clientId url: url];
     [auth start:^(NSError * _Nullable error, A0Credentials * _Nullable credentials {
        NSLog(@"error: %@, credentials: %@", error, credentials);
     }];
     ```

     Then from `AppDelegate` we just need to resume the OAuth2 Auth like this

     ```
     - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id>)*options {
        return [A0OAuth2 resumeAuthWithURL:url options:options];
     }
     ```

     - parameter callback: callback called with the result of the OAuth2 flow

     - returns: an object representing the current OAuth2 session.
     */
    @objc public func start(_ callback: @escaping (NSError?, Credentials?) -> Void) {
        self.webAuth.start { result in
            switch result {
            case .success(let credentials):
                callback(nil, credentials)
            case .failure(let cause):
                callback(cause as NSError, nil)
            }
        }
    }

    /**
    Removes Auth0 session and optionally remove the Identity Provider session.
    - seeAlso: [Auth0 Logout docs](https://auth0.com/docs/logout)

    For iOS 11+ you will need to ensure that the **Callback URL** has been added
    to the **Allowed Logout URLs** section of your application in the [Auth0 Dashboard](https://manage.auth0.com/#/applications/).

    ```
     A0WebAuth *auth = [[A0WebAuth alloc] initWithClientId:clientId url: url];
     [auth clearSessionWithFederated:NO:^(BOOL result) {
        // ...
     }];
    ```

    Remove Auth0 session and remove the IdP session.

    ```
    [auth clearSessionWithFederated:YES:^(BOOL result) {
       // ...
    }];
    ```

    - parameter federated: Bool to remove the IdP session
    - parameter callback: callback called with bool outcome of the call
    */
    @objc public func clearSession(federated: Bool, _ callback: @escaping (Bool) -> Void) {
        self.webAuth.clearSession(federated: federated) { result in
            callback(result)
        }
    }

    /**
     Avoid Auth0.swift sending its version on every request to Auth0 API.
     By default we collect our libraries and SDKs versions to help us during support and evaluate usage.

     - parameter enabled: if Auth0.swift should send it's version on every request.
     */
    @objc public func setTelemetryEnabled(_ enabled: Bool) {
        self.webAuth.tracking(enabled: enabled)
    }
}
#endif
