import Foundation

/// A minimal, dependency-free semantic version implementation.
///
/// Supports the subset of [SemVer 2.0.0](https://semver.org) needed to order
/// documentation versions and select the highest patch per major line:
/// `MAJOR.MINOR.PATCH` with an optional `-prerelease` segment (build metadata
/// after `+` is ignored). Ordering follows the SemVer precedence rules.
struct SemVer: Comparable, Equatable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int
    /// The dot-separated prerelease identifiers, or `nil` for a stable release.
    let prerelease: [String]?

    var isPrerelease: Bool { prerelease != nil }

    /// The canonical `MAJOR.MINOR.PATCH[-prerelease]` string.
    var description: String {
        let core = "\(major).\(minor).\(patch)"
        guard let prerelease, !prerelease.isEmpty else { return core }
        return "\(core)-\(prerelease.joined(separator: "."))"
    }

    /// Parses a version string, tolerating an optional leading `v` and ignoring
    /// any `+build` metadata. Returns `nil` if the core `MAJOR.MINOR.PATCH` is malformed.
    init?(_ raw: String) {
        var string = raw
        if string.hasPrefix("v") { string.removeFirst() }
        // Drop build metadata.
        if let plus = string.firstIndex(of: "+") {
            string = String(string[string.startIndex..<plus])
        }

        let coreAndPre = string.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let coreParts = coreAndPre[0].split(separator: ".", omittingEmptySubsequences: false)
        guard coreParts.count == 3,
              let major = Int(coreParts[0]),
              let minor = Int(coreParts[1]),
              let patch = Int(coreParts[2]) else {
            return nil
        }
        self.major = major
        self.minor = minor
        self.patch = patch

        if coreAndPre.count == 2 {
            let identifiers = coreAndPre[1].split(separator: ".").map(String.init)
            self.prerelease = identifiers.isEmpty ? nil : identifiers
        } else {
            self.prerelease = nil
        }
    }

    static func == (lhs: SemVer, rhs: SemVer) -> Bool {
        lhs.major == rhs.major && lhs.minor == rhs.minor &&
        lhs.patch == rhs.patch && lhs.prerelease == rhs.prerelease
    }

    static func < (lhs: SemVer, rhs: SemVer) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        // Core versions are equal; apply prerelease precedence.
        // A stable version (no prerelease) outranks any prerelease.
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil): return false
        case (nil, _?): return false   // lhs stable > rhs prerelease
        case (_?, nil): return true    // lhs prerelease < rhs stable
        case let (l?, r?): return SemVer.comparePrerelease(l, r) == .orderedAscending
        }
    }

    /// Compares two prerelease identifier lists per SemVer rule 11: numeric
    /// identifiers compare numerically, alphanumeric ones lexically; numeric
    /// has lower precedence than alphanumeric; a larger set of fields wins when
    /// all preceding fields are equal.
    private static func comparePrerelease(_ lhs: [String], _ rhs: [String]) -> ComparisonResult {
        for (l, r) in zip(lhs, rhs) {
            if l == r { continue }
            let lNum = Int(l)
            let rNum = Int(r)
            switch (lNum, rNum) {
            case let (a?, b?):
                return a < b ? .orderedAscending : .orderedDescending
            case (_?, nil):
                return .orderedAscending  // numeric < alphanumeric
            case (nil, _?):
                return .orderedDescending
            case (nil, nil):
                return l < r ? .orderedAscending : .orderedDescending
            }
        }
        if lhs.count == rhs.count { return .orderedSame }
        return lhs.count < rhs.count ? .orderedAscending : .orderedDescending
    }
}
