import Foundation

/// Decides which documentation versions to keep, mirroring the policy used by
/// react-native-auth0's `manage-doc-versions.js`.
///
/// At most two major version lines are retained at any time:
/// - When the current release is **stable**, keep the highest patch of each of
///   the two most recent stable majors.
/// - When the current release is a **prerelease** (alpha/beta), keep the current
///   prerelease plus the newest stable version below it. That stable may share
///   the current major (e.g. `2.23.0` while cutting `2.24.0-beta.1`) or belong to
///   an earlier major (e.g. `2.23.0` while cutting `3.0.0-beta.1`); either way the
///   stable users currently rely on is never dropped while a prerelease is live.
enum Retention {
    /// - Parameters:
    ///   - current: The version being released.
    ///   - existing: All versions already published (folder-derived). May or may
    ///     not already contain `current`.
    /// - Returns: The versions to keep, sorted newest-first.
    static func versionsToKeep(current: SemVer, existing: [SemVer]) -> [SemVer] {
        // Deduplicate the union of existing + current, newest first.
        var seen = Set<String>()
        let all = ([current] + existing)
            .filter { seen.insert($0.description).inserted }
            .sorted(by: >)

        if current.isPrerelease {
            // Keep the current prerelease + newest stable below it (same major or
            // earlier). `all` is sorted descending and a stable outranks its own
            // prerelease, so the first stable < current is the one users rely on.
            let latestStableBelow = all.first {
                !$0.isPrerelease && $0 < current
            }
            return [current] + (latestStableBelow.map { [$0] } ?? [])
        } else {
            // Keep the highest version of each of the two most recent stable majors.
            let stable = all.filter { !$0.isPrerelease }
            var majorsSeen = [Int]()
            var kept = [SemVer]()
            for version in stable {
                if majorsSeen.contains(version.major) { continue }
                majorsSeen.append(version.major)
                kept.append(version)  // first seen per major is the highest (sorted desc)
                if majorsSeen.count == 2 { break }
            }
            return kept
        }
    }
}
