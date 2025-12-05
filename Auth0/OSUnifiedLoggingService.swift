import Foundation
import os.log

// Avoid naming conflict with Auth0Logger protocol
typealias OSLogger = os.Logger

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
struct OSUnifiedLoggingService: UnifiedLogging {
    
    /// Internal marker class used to identify the SDK bundle.
    private final class BundleMarker {}
    
    /// Centralized subsystem identifier for all Auth0 logs.
    static let subsystem = Bundle(for: BundleMarker.self).bundleIdentifier ?? "com.auth0.Auth0"
    
    /// Cached loggers for each category to avoid repeated allocations.
    private static let loggers: [LogCategory: OSLogger] = {
        var loggers: [LogCategory: OSLogger] = [:]
        loggers[.networkTracing] = OSLogger(subsystem: subsystem, category: LogCategory.networkTracing.rawValue)
        loggers[.configuration] = OSLogger(subsystem: subsystem, category: LogCategory.configuration.rawValue)
        return loggers
    }()
    
    func log(
        _ category: LogCategory,
        level: LogLevel,
        message: @autoclosure () -> String,
        isPublic: Bool = false
    ) {
        guard let logger = Self.loggers[category] else { return }
        
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
