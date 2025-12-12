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
    func log(
        _ category: LogCategory,
        level: LogLevel,
        message: @autoclosure () -> String
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
    
    /// Logs a message with privacy redaction.
    ///
    /// All messages use `.private` privacy level, which means:
    /// - **Debug/Info**: Never persisted to disk. Only visible during active debugging in Xcode Console.
    /// - **Warning/Error/Fault**: Persisted to system logs but entire message is redacted as `<private>`
    ///   when exported or viewed without debugger attached. Only visible unredacted during active debugging.

    func log(
        _ category: LogCategory,
        level: LogLevel,
        message: @autoclosure () -> String
    ) {
        guard let logger = Self.loggers[category] else { return }
        
        let messageString = message()
        
        switch level {
        case .debug:
            logger.debug("\(messageString, privacy: .private)")
        case .info:
            logger.info("\(messageString, privacy: .private)")
        case .warning:
            logger.warning("\(messageString, privacy: .private)")
        case .error:
            logger.error("\(messageString, privacy: .private)")
        case .fault:
            logger.fault("\(messageString, privacy: .private)")
        }
    }
}
