import Foundation
import OSLog

/// Logger for debugging purposes.
public protocol Auth0Logger {

    /// Log an HTTP request.
    func trace(request: URLRequest, session: URLSession)

    /// Log an HTTP response.
    func trace(response: URLResponse, data: Data?)

    /// Log a URL.
    func trace(url: URL, source: String?)

}

// MARK: - Unified Logging System

/// Represents different categories of logs within the SDK.
enum LogCategory: String {
    case auth = "Auth0"
    case network = "Network"
    case configuration = "Configuration"
    
    var logger: Logger {
        Logger(subsystem: Auth0Log.subsystem, category: rawValue)
    }
}

/// Log levels supported by the unified logging system.
enum LogLevel {
    case debug
    case info
    case warning
    case error
    case fault
}

/// Unified logging interface for the SDK.
/// Provides a consistent, type-safe API for logging across all SDK components.
enum Auth0Log {
    
    /// Centralized subsystem identifier for all Auth0 logs.
    private static let subsystem = Bundle(for: DefaultLogger.self).bundleIdentifier ?? "com.auth0.Auth0"
    
    /// Log a message with the specified category and level.
    /// - Parameters:
    ///   - category: The log category (e.g., request, configuration)
    ///   - level: The severity level of the log
    ///   - message: The message to log
    ///   - isPublic: Whether the message should be visible in system logs (default: true for debugging)
    static func log(
        _ category: LogCategory,
        level: LogLevel = .debug,
        message: @autoclosure () -> String,
        isPublic: Bool = true
    ) {
        let logger = category.logger
        let messageString = message()
        let privacy: OSLogPrivacy = isPublic ? .public : .private
        
        switch level {
        case .debug:
            logger.debug("\(messageString, privacy: privacy)")
        case .info:
            logger.info("\(messageString, privacy: privacy)")
        case .warning:
            logger.warning("\(messageString, privacy: privacy)")
        case .error:
            logger.error("\(messageString, privacy: privacy)")
        case .fault:
            logger.fault("\(messageString, privacy: privacy)")
        }
    }
    
    /// Convenience method for debug logs.
    static func debug(_ category: LogCategory, _ message: @autoclosure () -> String, isPublic: Bool = true) {
        log(category, level: .debug, message: message(), isPublic: isPublic)
    }
    
    /// Convenience method for info logs.
    static func info(_ category: LogCategory, _ message: @autoclosure () -> String, isPublic: Bool = true) {
        log(category, level: .info, message: message(), isPublic: isPublic)
    }
    
    /// Convenience method for warning logs.
    static func warning(_ category: LogCategory, _ message: @autoclosure () -> String, isPublic: Bool = true) {
        log(category, level: .warning, message: message(), isPublic: isPublic)
    }
    
    /// Convenience method for error logs.
    static func error(_ category: LogCategory, _ message: @autoclosure () -> String, isPublic: Bool = true) {
        log(category, level: .error, message: message(), isPublic: isPublic)
    }
    
    /// Convenience method for fault logs (critical system errors).
    static func fault(_ category: LogCategory, _ message: @autoclosure () -> String, isPublic: Bool = true) {
        log(category, level: .fault, message: message(), isPublic: isPublic)
    }
}

// MARK: - Internal Logging Output

protocol LoggerOutput {
    func log(message: String)
    func newLine()
}

struct DefaultOutput: LoggerOutput {
    func log(message: String) {
        Auth0Log.debug(.auth, message)
    }
    
    func newLine() {
        Auth0Log.debug(.auth, "")
    }
}

struct DefaultLogger: Auth0Logger {

    let output: LoggerOutput

    init(output: LoggerOutput = DefaultOutput()) {
        self.output = output
    }

    func trace(request: URLRequest, session: URLSession) {
        guard let method = request.httpMethod, let url = request.url?.absoluteString else { return }
        output.log(message: "\(method) \(url) HTTP/1.1")
        session.configuration.httpAdditionalHeaders?.forEach { key, value in output.log(message: "\(key): \(value)") }
        request.allHTTPHeaderFields?.forEach { key, value in output.log(message: "\(key): \(value)") }
        if let data = request.httpBody, let string = String(data: data, encoding: .utf8) {
            output.newLine()
            output.log(message: string)
        }
        output.newLine()
    }

    func trace(response: URLResponse, data: Data?) {
        if let http = response as? HTTPURLResponse {
            output.log(message: "HTTP/1.1 \(http.statusCode)")
            http.allHeaderFields.forEach { key, value in output.log(message: "\(key): \(value)") }
            if let data = data, let string = String(data: data, encoding: .utf8) {
                output.newLine()
                output.log(message: string)
            }
            output.newLine()
        }
    }

    func trace(url: URL, source: String?) {
        output.log(message: "\(source ?? "URL"): \(url.absoluteString)")
    }

}
