#if os(macOS)
import AppKit

extension NSApplication {

    static func shared() -> NSApplication? {
        return NSApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? NSApplication
    }

}
#endif
