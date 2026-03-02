import Foundation
import os.log

// MARK: - Unified Logging System

/// Represents different categories of logs within the SDK.
enum LogCategory: String {
    /// networkTracing category is used for  the network request and response traces
    case networkTracing = "NetworkTracing"
    /// configuration category is used for SDK configuration related logs
    case configuration = "Configuration"
}

/// Log levels supported by the unified logging system.
enum LogLevel {
    /// Detailed information for debugging
    case debug
    /// General informational messages
    case info
    /// Warning messages for potentially problematic situations
    case warning
    /// Error messages for failures
    case error
    /// Critical system errors
    case fault
}

/// Unified logging interface for the SDK.
/// Provides a consistent, type-safe API for logging across all SDK components.
enum Auth0Log {
    
    /// Shared logging service instance (can be replaced for testing).
    nonisolated(unsafe) static var loggingService: UnifiedLogging = OSUnifiedLoggingService()
    
    /// Centralized subsystem identifier for all Auth0 logs.
    static var subsystem: String { OSUnifiedLoggingService.subsystem }
    
    /// Log a message with the specified category and level.
    ///
    /// Use this method for fine-grained control over logging. For common use cases,
    /// prefer the convenience methods: `debug()`, `info()`, `warning()`, `error()`, `fault()`.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering and organization. See `LogCategory` for available categories.
    ///   - level: The severity level of the log. Defaults to `.debug`. See `LogLevel` for available levels.
    ///   - message: The message to log. Evaluated lazily via autoclosure for performance.
    static func log(
        _ category: LogCategory,
        level: LogLevel = .debug,
        message: String
    ) {
        loggingService.log(category, level: level, message: message)
    }
    
    /// Log a debug message.
    ///
    /// Use for detailed information useful during development and debugging.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering
    ///   - message: The message to log
    static func debug(
        _ category: LogCategory,
        _ message: String
    ) {
        log(category, level: .debug, message: message)
    }
    
    /// Log an informational message.
    ///
    /// Use for general informational messages about application state.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering
    ///   - message: The message to log
    static func info(
        _ category: LogCategory,
        _ message:  String
    ) {
        log(category, level: .info, message: message)
    }
    
    /// Log a warning message.
    ///
    /// Use for potentially problematic situations that aren't errors.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering
    ///   - message: The message to log
    static func warning(
        _ category: LogCategory,
        _ message: String
    ) {
        log(category, level: .warning, message: message)
    }
    
    /// Log an error message.
    ///
    /// Use for error conditions and failures that need attention.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering
    ///   - message: The message to log
    static func error(
        _ category: LogCategory,
        _ message: String
    ) {
        log(category, level: .error, message: message)
    }
    
    /// Log a fault message for critical system errors.
    ///
    /// Use for serious errors that may cause data loss or application instability.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering
    ///   - message: The message to log
    static func fault(
        _ category: LogCategory,
        _ message: @autoclosure () -> String
    ) {
        log(category, level: .fault, message: message())
    }
}
