import Foundation
import os.log

// Avoid naming conflict with Auth0Logger protocol
typealias OSLogger = os.Logger

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

/// Protocol for unified logging operations.
protocol UnifiedLogging {
    /// Log a message with the specified parameters.
    /// - Parameters:
    ///   - category: The log category for filtering (e.g., `.networkTracing`, `.configuration`)
    ///   - level: The severity level (`.debug`, `.info`, `.warning`, `.error`, `.fault`)
    ///   - message: The message to log (lazy-evaluated via autoclosure)
    ///   - isPublic: Whether the message is visible in system logs. Defaults to `false` to protect sensitive data
    func log(
        _ category: LogCategory,
        level: LogLevel,
        message: @autoclosure () -> String,
        isPublic: Bool
    )
}

/// Production OSLog-based logging implementation.
struct OSLogService: UnifiedLogging {
    
    /// Internal marker class used to identify the SDK bundle.
    private final class BundleMarker {}
    
    /// Centralized subsystem identifier for all Auth0 logs.
    static let subsystem = Bundle(for: BundleMarker.self).bundleIdentifier ?? "com.auth0.Auth0"
    
    func log(
        _ category: LogCategory,
        level: LogLevel,
        message: @autoclosure () -> String,
        isPublic: Bool = false
    ) {
        let logger = OSLogger(subsystem: Self.subsystem, category: category.rawValue)
        let messageString = message()
        
        switch (level, isPublic) {
        case (.debug, true):
            logger.debug("\(messageString, privacy: .public)")
        case (.debug, false):
            logger.debug("\(messageString, privacy: .private)")
        case (.info, true):
            logger.info("\(messageString, privacy: .public)")
        case (.info, false):
            logger.info("\(messageString, privacy: .private)")
        case (.warning, true):
            logger.warning("\(messageString, privacy: .public)")
        case (.warning, false):
            logger.warning("\(messageString, privacy: .private)")
        case (.error, true):
            logger.error("\(messageString, privacy: .public)")
        case (.error, false):
            logger.error("\(messageString, privacy: .private)")
        case (.fault, true):
            logger.fault("\(messageString, privacy: .public)")
        case (.fault, false):
            logger.fault("\(messageString, privacy: .private)")
        }
    }
}

/// Unified logging interface for the SDK.
/// Provides a consistent, type-safe API for logging across all SDK components.
enum Auth0Log {
    
    /// Shared logging service instance (can be replaced for testing).
    static var loggingService: UnifiedLogging = OSLogService()
    
    /// Centralized subsystem identifier for all Auth0 logs.
    static var subsystem: String { OSLogService.subsystem }
    
    /// Log a message with the specified category and level.
    ///
    /// Use this method for fine-grained control over logging. For common use cases,
    /// prefer the convenience methods: `debug()`, `info()`, `warning()`, `error()`, `fault()`.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering and organization. See `LogCategory` for available categories.
    ///   - level: The severity level of the log. Defaults to `.debug`. See `LogLevel` for available levels.
    ///   - message: The message to log. Evaluated lazily via autoclosure for performance.
    ///   - isPublic: Whether the message is visible in system logs. Defaults to `false` to protect sensitive data.
    ///     Set to `true` only for non-sensitive debugging information.
    static func log(
        _ category: LogCategory,
        level: LogLevel = .debug,
        message: @autoclosure () -> String,
        isPublic: Bool = false
    ) {
        loggingService.log(category, level: level, message: message(), isPublic: isPublic)
    }
    
    /// Log a debug message.
    ///
    /// Use for detailed information useful during development and debugging.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering
    ///   - message: The message to log
    ///   - isPublic: Whether the message is visible in system logs (default: `false`)
    static func debug(
        _ category: LogCategory,
        _ message: @autoclosure () -> String,
        isPublic: Bool = false
    ) {
        log(category, level: .debug, message: message(), isPublic: isPublic)
    }
    
    /// Log an informational message.
    ///
    /// Use for general informational messages about application state.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering
    ///   - message: The message to log
    ///   - isPublic: Whether the message is visible in system logs (default: `false`)
    static func info(
        _ category: LogCategory,
        _ message: @autoclosure () -> String,
        isPublic: Bool = false
    ) {
        log(category, level: .info, message: message(), isPublic: isPublic)
    }
    
    /// Log a warning message.
    ///
    /// Use for potentially problematic situations that aren't errors.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering
    ///   - message: The message to log
    ///   - isPublic: Whether the message is visible in system logs (default: `false`)
    static func warning(
        _ category: LogCategory,
        _ message: @autoclosure () -> String,
        isPublic: Bool = false
    ) {
        log(category, level: .warning, message: message(), isPublic: isPublic)
    }
    
    /// Log an error message.
    ///
    /// Use for error conditions and failures that need attention.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering
    ///   - message: The message to log
    ///   - isPublic: Whether the message is visible in system logs (default: `false`)
    static func error(
        _ category: LogCategory,
        _ message: @autoclosure () -> String,
        isPublic: Bool = false
    ) {
        log(category, level: .error, message: message(), isPublic: isPublic)
    }
    
    /// Log a fault message for critical system errors.
    ///
    /// Use for serious errors that may cause data loss or application instability.
    ///
    /// - Parameters:
    ///   - category: The log category for filtering
    ///   - message: The message to log
    ///   - isPublic: Whether the message is visible in system logs (default: `false`)
    static func fault(
        _ category: LogCategory,
        _ message: @autoclosure () -> String,
        isPublic: Bool = false
    ) {
        log(category, level: .fault, message: message(), isPublic: isPublic)
    }
}
