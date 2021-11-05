import Foundation

public extension NSError {
    @objc var a0_isManagementError: Bool { return self.domain == ManagementError.errorDomain }
    @objc var a0_isAuthenticationError: Bool { return self.domain == AuthenticationError.errorDomain }
}
