#if WEB_AUTH_PLATFORM
import Foundation

/// Transaction for PAR (Pushed Authorization Request) code-only flow.
///
/// This transaction handles the authorize flow when using PAR and returns
/// just the authorization code (not credentials). The code is then exchanged
/// for tokens by the BFF (Backend-For-Frontend).
class PARCodeTransaction: NSObject, AuthTransaction {
    
    private(set) var userAgent: WebAuthUserAgent?
    
    let redirectURL: URL
    let logger: Logger?
    let callback: (WebAuthResult<AuthorizationCode>) -> Void
    
    init(redirectURL: URL,
         userAgent: WebAuthUserAgent,
         logger: Logger?,
         callback: @escaping (WebAuthResult<AuthorizationCode>) -> Void) {
        self.redirectURL = redirectURL
        self.userAgent = userAgent
        self.logger = logger
        self.callback = callback
        super.init()
    }
    
    func cancel() {
        self.finishUserAgent(with: .failure(WebAuthError(code: .userCancelled)))
    }
    
    func resume(_ url: URL) -> Bool {
        self.logger?.trace(url: url, source: "Callback URL")
        return handleCallback(url: url)
    }
    
    private func handleCallback(url: URL) -> Bool {
        guard url.absoluteString.lowercased().hasPrefix(self.redirectURL.absoluteString.lowercased()),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            let error = WebAuthError(code: .unknown("Invalid callback URL"))
            finishUserAgent(with: .failure(error))
            return false
        }
        
        var items: [String: String] = [:]
        // Parse query parameters
        components.queryItems?.forEach { items[$0.name] = $0.value }
        // Also check fragment for implicit flows
        if let fragment = components.fragment {
            let fragmentItems = fragment.split(separator: "&").compactMap { pair -> (String, String)? in
                let parts = pair.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { return nil }
                return (String(parts[0]), String(parts[1]))
            }
            fragmentItems.forEach { items[$0.0] = $0.1 }
        }
        
        // Check for error response from Auth0
        if let error = items["error"] {
            let description = items["error_description"] ?? error
            let authError = AuthenticationError(
                info: ["error": error, "error_description": description],
                statusCode: 0
            )
            let webAuthError = WebAuthError(code: .other, cause: authError)
            self.callback(.failure(webAuthError))
            finishUserAgent(with: .success(()))
            return true
        }
        
        // Get state from callback (if present)
        let returnedState = items["state"]
        
        // Extract authorization code
        guard let code = items["code"] else {
            let error = WebAuthError(code: .noAuthorizationCode(items))
            self.callback(.failure(error))
            finishUserAgent(with: .success(()))
            return true
        }
        
        // Success - return the authorization code
        let result = AuthorizationCode(code: code, state: returnedState)
        self.callback(.success(result))
        finishUserAgent(with: .success(()))
        return true
    }
    
    private func finishUserAgent(with result: WebAuthResult<Void>) {
        self.userAgent?.finish(with: result)
        self.userAgent = nil
    }
}
#endif
