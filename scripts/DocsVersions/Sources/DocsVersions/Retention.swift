import Foundation

/// Decides which documentation versions to keep.
///
/// Two major version lines are retained:
/// - the **latest major** — represented by its latest release, whether beta or
///   stable. If that major has a stable, its betas are dropped (stable wins);
///   otherwise its latest prerelease is kept, so a live next-major preview (e.g.
///   `3.0.0-beta.2`) survives while a lower-major stable ships.
/// - the **previous major** — represented by its latest stable release.
///
/// Because the current release is always among the newest, it is always kept.
/// When the current release is a **prerelease**, the latest stable below it is
/// additionally retained even if it shares the current major (e.g. `2.24.0-beta.1`
/// keeps `2.23.0`), so the stable users rely on stays live during a preview.
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
            // Keep the current prerelease + the newest stable below it, so the
            // stable release users currently rely on stays live while a preview
            // is published — whether that stable shares the current major (e.g.
            // 2.24.0-beta.1 over 2.23.0) or an earlier one (3.0.0-beta.1 over
            // 2.23.0).
            let previousStable = all.first { !$0.isPrerelease && $0 < current }
            return [current] + (previousStable.map { [$0] } ?? [])
        } else {
            // Keep the current release plus one representative of the next most
            // recent *other* major line. `all` is sorted descending, so the
            // first version whose major differs from `current` identifies that
            // major. Represent it by its latest stable when one exists, otherwise
            // its latest prerelease — so a live next-major preview (e.g.
            // 3.0.0-beta.2 while cutting a 2.x stable) is retained, and once that
            // major has a stable its betas are dropped.
            var kept = [current]
            if let otherMajor = all.first(where: { $0.major != current.major })?.major {
                let inMajor = all.filter { $0.major == otherMajor }
                let representative = inMajor.first { !$0.isPrerelease } ?? inMajor[0]
                kept.append(representative)
            }
            return kept.sorted(by: >)
        }
    }
}
