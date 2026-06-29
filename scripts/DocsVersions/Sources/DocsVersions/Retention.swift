import Foundation

/// Decides which documentation versions to keep, mirroring the policy used by
/// react-native-auth0's `manage-doc-versions.js`.
///
/// At most two major version lines are retained at any time:
/// - When the current release is **stable**, keep the highest patch of each of
///   the two most recent stable majors.
/// - When the current release is a **prerelease** (alpha/beta), keep the current
///   prerelease plus the highest stable version of the most recent *earlier*
///   stable major.
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
            // Keep the current prerelease + latest stable of an earlier major.
            let latestEarlierStable = all.first {
                !$0.isPrerelease && $0.major < current.major
            }
            return [current] + (latestEarlierStable.map { [$0] } ?? [])
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
