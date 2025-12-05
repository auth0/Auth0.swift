import Foundation
import os.log

// Avoid naming conflict with Auth0Logger protocol
typealias OSLogger = os.Logger

/// Production OSLog-based logging implementation.
struct OSUnifiedLoggingService: UnifiedLogging {
    
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
