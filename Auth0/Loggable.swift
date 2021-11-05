import Foundation

public protocol Loggable {

    var logger: Logger? { get set }

}

public extension Loggable {

    /**
     Turn on Auth0.swift debug logging of HTTP requests and OAuth2 flow (iOS only) with a custom logger.

     - parameter logger: logger used to print log statements
     - note: By default all logging is **disabled**
     - important: Logging should be turned on/off **before** making request to Auth0 for the flag to take effect.
     */
    func using(logger: Logger) -> Self {
        var loggable = self
        loggable.logger = logger
        return loggable
    }

    /**
     Turn on/off Auth0.swift debug logging of HTTP requests and OAuth2 flow (iOS only).

     - parameter enabled: optional flag to turn on/off logging
     - note: By default all logging is **disabled**
     - important: Logging should be turned on/off **before** making request to Auth0 for the flag to take effect.
     */
    func logging(enabled: Bool) -> Self {
        var loggable = self
        if enabled {
            loggable.logger = DefaultLogger()
        } else {
            loggable.logger = nil
        }
        return loggable
    }
}
