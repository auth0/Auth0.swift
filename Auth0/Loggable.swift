import Foundation

/// A type that can log statements for debugging purposes.
public protocol Loggable {

    /// Logger used to print log statements.
    var logger: Logger? { get set }

}

public extension Loggable {

    /**
     Turn on Auth0.swift debug logging of HTTP requests and responses with a custom logger.

     - Parameter logger: Logger used to print log statements.
     - Note: By default all logging is **disabled**.
     - Important: Logging should be turned on/off **before** making request to Auth0 for the flag to take effect.
     */
    func using(logger: Logger) -> Self {
        var loggable = self
        loggable.logger = logger
        return loggable
    }

    /**
     Turn on/off Auth0.swift debug logging of HTTP requests and responses.

     - Parameter enabled: Flag to turn logging on/off.
     - Note: By default all logging is **disabled**.
     - Important: For the flag to take effect, logging should be turned on/off **before** making requests to Auth0.
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
