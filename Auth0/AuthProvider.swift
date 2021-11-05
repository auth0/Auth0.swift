#if WEB_AUTH_PLATFORM
/**
 The AuthProvider protocol is adopted by objects that are to be used as Native Authentication
 handlers. An object implementing this protocol is intended to supersede the default authentication
 model for a given connection name with its own native implementation.

 ```
 struct Facebook: AuthProvider {

     func login(withConnection connection: String, scope: String, parameters: [String : Any]) -> NativeAuthTransaction {
         let transaction = FacebookNativeAuthTransaction()
         ...
         return transaction
     }
 
     static func isAvailable() -> Bool {
         return true
     }

 ```
 */
@available(*, deprecated, message: "not available for OIDC-conformant clients")
public protocol AuthProvider {
    func login(withConnection connection: String, scope: String, parameters: [String: Any]) -> NativeAuthTransaction

    /**
     Determine if the Auth method used by the Provider is available on the device.
     e.g. If using a Twitter Auth provider it should check the presence of a Twitter account on the device.

     If a Auth is performed on a provider that returns `false` the transaction will fail with an error.

     - returns: Bool if the AuthProvider is available on the device
     */
    static func isAvailable() -> Bool
}
#endif
