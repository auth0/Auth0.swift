import Foundation

// MARK: - CLI

/// Folds a freshly-built DocC static site into a versioned GitHub Pages layout.
///
/// Usage:
///   DocsVersions --site-root <dir> --new-build <dir> [--new-build-root <dir>]
///                [--version X.Y.Z] [--version-file <path>] [--base-path Auth0.swift]
///
/// - `--site-root`       The gh-pages working copy to update in place (created if missing).
/// - `--new-build`       The freshly transformed static site to fold in as `v<version>/`.
/// - `--new-build-root`  Optional. A second transform of the same version built with the bare
///                       base path, served directly at the site root so the default docs use a
///                       version-less URL. Provided only for stable releases; when present the
///                       previous stable's root content is replaced by it.
/// - `--version`         The version being published. If omitted, read from `--version-file`.
/// - `--version-file`    Path to `Auth0/Version.swift` (default: `Auth0/Version.swift`).
/// - `--base-path`       The Pages base path used for the root asset URL (default: `Auth0.swift`).

let arguments = CommandLineArguments(CommandLine.arguments)
let fileManager = FileManager.default

guard let siteRootPath = arguments["--site-root"] else {
    fail("Missing required --site-root <dir>")
}
guard let newBuildPath = arguments["--new-build"] else {
    fail("Missing required --new-build <dir>")
}
let newBuildRootPath = arguments["--new-build-root"]
let basePath = arguments["--base-path"] ?? "Auth0.swift"
let versionFile = arguments["--version-file"] ?? "Auth0/Version.swift"

let versionString: String
if let explicit = arguments["--version"] {
    versionString = explicit
} else {
    versionString = readVersion(fromSwiftFile: versionFile)
}

guard let current = SemVer(versionString) else {
    fail("Could not parse version '\(versionString)'")
}

let siteRoot = URL(fileURLWithPath: siteRootPath, isDirectory: true)
let newBuild = URL(fileURLWithPath: newBuildPath, isDirectory: true)

print("📦 Publishing documentation for v\(current)")

do {
    try fileManager.createDirectory(at: siteRoot, withIntermediateDirectories: true)
} catch {
    fail("Could not create site root directory at \(siteRoot.path): \(error)")
}

// MARK: 1. Overwrite the current version's folder

let versionFolderName = "v\(current)"
let versionFolder = siteRoot.appendingPathComponent(versionFolderName, isDirectory: true)
if fileManager.fileExists(atPath: versionFolder.path) {
    print("♻️  Replacing existing \(versionFolderName)/")
    try remove(versionFolder)
}

guard fileManager.fileExists(atPath: newBuild.path) else {
    fail("New build directory does not exist: \(newBuild.path)")
}
try move(newBuild, to: versionFolder)
print("✅ Placed new build at \(versionFolderName)/")

// MARK: 2. Inject the version-selector script into the new version's HTML

let scriptTag = "<script defer src=\"/\(basePath)/version-selector.js\"></script>"
let injectedCount = try injectScript(scriptTag, intoHTMLUnder: versionFolder)
guard injectedCount > 0 else {
    fail("No HTML files were updated with version-selector.js under \(versionFolder.path)")
}
print("🔧 Injected version selector into \(injectedCount) HTML file(s)")

// MARK: 3. Apply retention policy and prune

let existing = existingVersionFolders(in: siteRoot)
let keep = Retention.versionsToKeep(current: current, existing: existing)
let keepSet = Set(keep.map { $0.description })

for version in existing where !keepSet.contains(version.description) {
    let folder = siteRoot.appendingPathComponent("v\(version)", isDirectory: true)
    print("🗑️  Pruning v\(version)/")
    try remove(folder)
}
print("📚 Keeping \(keep.count) version(s): \(keep.map { "v\($0)" }.joined(separator: ", "))")

// MARK: 4. Mirror the stable version at the site root

// A stable release ships a second build transformed with the bare base path so
// the default docs serve from the site root (version-less URL = the historical
// canonical URL). Prereleases never carry this, so the root keeps serving the
// last stable. The root is a disposable mirror; each version's own /v<x>/ folder
// remains the source of truth.
if let newBuildRootPath {
    let newBuildRoot = URL(fileURLWithPath: newBuildRootPath, isDirectory: true)
    guard fileManager.fileExists(atPath: newBuildRoot.path) else {
        fail("Root build directory does not exist: \(newBuildRoot.path)")
    }
    print("🏠 Replacing root content with v\(current)")
    try clearRootDocContent(in: siteRoot)
    try moveContents(of: newBuildRoot, into: siteRoot)
    let rootInjected = try injectScript(scriptTag, intoHTMLUnder: siteRoot)
    print("🔧 Injected version selector into \(rootInjected) root HTML file(s)")
}

// MARK: 5. Write root metadata, selector script, redirect, .nojekyll

// The dropdown defaults to the newest stable release so visitors are not
// dropped onto prerelease docs. Fall back to the newest overall version only
// when nothing stable has been published yet.
let newestStable = keep.first { !$0.isPrerelease }
let stable = newestStable ?? keep[0]

try writeVersionsJSON(keep: keep, stable: stable, at: siteRoot)
try copyVersionSelector(to: siteRoot)
try writeNoJekyll(at: siteRoot)

// The bare site root (e.g. /Auth0.swift/) must land on a working doc page. DocC's
// own top-level index.html is an SPA loader stub hardcoded to baseUrl "/", so its
// asset URLs (/js, /css) 404 under the /<base-path>/ prefix — leaving the page
// blank. We always overwrite it with our own redirect to a fully base-path-scoped
// landing page. When stable content owns the root, the version-less
// documentation/auth0/ (which bakes the correct base path) is canonical; otherwise
// redirect into the stable version's /v<version>/ folder.
let rootHasStableContent = fileManager.fileExists(
    atPath: siteRoot.appendingPathComponent("documentation", isDirectory: true).path
)
if rootHasStableContent {
    try writeRootRedirect(toDocPath: "documentation/auth0/", basePath: basePath, at: siteRoot)
    print("🎉 Done. Stable v\(stable) served at root.")
} else {
    try writeRootRedirect(toDocPath: "v\(stable)/documentation/auth0/", basePath: basePath, at: siteRoot)
    print("🎉 Done. Root redirects to stable v\(stable).")
}

// MARK: - Steps

/// Reads `let version = "X.Y.Z"` from a Swift source file.
func readVersion(fromSwiftFile path: String) -> String {
    guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
        fail("Could not read version file: \(path)")
    }
    // Match: let version = "X.Y.Z"
    let pattern = #"let\s+version\s*=\s*"([^"]+)""#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: contents, range: NSRange(contents.startIndex..., in: contents)),
          let range = Range(match.range(at: 1), in: contents) else {
        fail("Could not find `let version = \"...\"` in \(path)")
    }
    return String(contents[range])
}

/// Lists `v<semver>` subfolders of the site root as parsed `SemVer` values.
func existingVersionFolders(in root: URL) -> [SemVer] {
    let entries = (try? fileManager.contentsOfDirectory(atPath: root.path)) ?? []
    return entries.compactMap { name -> SemVer? in
        guard name.hasPrefix("v") else { return nil }
        var isDir: ObjCBool = false
        let full = root.appendingPathComponent(name)
        guard fileManager.fileExists(atPath: full.path, isDirectory: &isDir), isDir.boolValue else {
            return nil
        }
        return SemVer(String(name.dropFirst()))
    }
}

/// Injects `scriptTag` immediately before `</head>` in every `.html` file under
/// `folder`. Skips files that already contain the tag. Returns the count modified.
@discardableResult
func injectScript(_ scriptTag: String, intoHTMLUnder folder: URL) throws -> Int {
    guard let enumerator = fileManager.enumerator(at: folder, includingPropertiesForKeys: nil) else {
        return 0
    }
    var count = 0
    for case let url as URL in enumerator where url.pathExtension == "html" {
        var html = try String(contentsOf: url, encoding: .utf8)
        if html.contains(scriptTag) { continue }
        guard let range = html.range(of: "</head>") else { continue }
        html.replaceSubrange(range, with: scriptTag + "</head>")
        try html.write(to: url, atomically: true, encoding: .utf8)
        count += 1
    }
    return count
}

func writeVersionsJSON(keep: [SemVer], stable: SemVer, at root: URL) throws {
    let versions = keep.map { v -> [String: String] in
        ["version": v.description, "name": "v\(v)", "path": "v\(v)"]
    }
    let payload: [String: Any] = ["versions": versions, "stable": "v\(stable)"]
    let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: root.appendingPathComponent("versions.json"))
}

/// Copies the bundled `version-selector.js` resource to the site root.
func copyVersionSelector(to root: URL) throws {
    guard let source = Bundle.module.url(forResource: "version-selector", withExtension: "js") else {
        fail("Bundled version-selector.js not found in resources")
    }
    let destination = root.appendingPathComponent("version-selector.js")
    if fileManager.fileExists(atPath: destination.path) { try remove(destination) }
    try fileManager.copyItem(at: source, to: destination)
}

/// Writes the site-root `index.html`, overwriting DocC's baseUrl-"/" loader stub
/// with a redirect to a base-path-scoped landing page. `docPath` is relative to
/// the site root (e.g. `documentation/auth0/` for root-served stable, or
/// `v<version>/documentation/auth0/` when redirecting into a version folder).
func writeRootRedirect(toDocPath docPath: String, basePath: String, at root: URL) throws {
    let html = """
    <!DOCTYPE html>
    <html>
      <head>
        <meta http-equiv="refresh" content="0; url=\(docPath)" />
        <link rel="canonical" href="/\(basePath)/\(docPath)" />
      </head>
      <body>
        <a href="\(docPath)">Redirect to the latest documentation</a>
      </body>
    </html>

    """
    try html.write(to: root.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
}

func writeNoJekyll(at root: URL) throws {
    let url = root.appendingPathComponent(".nojekyll")
    if !fileManager.fileExists(atPath: url.path) {
        try Data().write(to: url)
    }
}

// MARK: - File helpers

/// Removes the previous stable's DocC content from the site root, leaving the
/// `v<version>/` aliases and shared site files (`versions.json`,
/// `version-selector.js`, `.nojekyll`) untouched.
func clearRootDocContent(in root: URL) throws {
    // Top-level entries the root mirror must never delete: every version alias
    // folder (`v…`) and the shared site files. Everything else at the root is
    // the previous stable's DocC output and is replaced wholesale.
    let preserved: Set<String> = ["versions.json", "version-selector.js", ".nojekyll"]
    let entries = (try? fileManager.contentsOfDirectory(atPath: root.path)) ?? []
    for name in entries {
        if name.hasPrefix("v") || preserved.contains(name) { continue }
        try remove(root.appendingPathComponent(name))
    }
}

/// Moves every top-level entry of `source` into `destination`, replacing any
/// existing entry of the same name.
func moveContents(of source: URL, into destination: URL) throws {
    let entries = try fileManager.contentsOfDirectory(atPath: source.path)
    for name in entries {
        try move(source.appendingPathComponent(name),
                 to: destination.appendingPathComponent(name))
    }
}

func move(_ source: URL, to destination: URL) throws {
    if fileManager.fileExists(atPath: destination.path) { try remove(destination) }
    try fileManager.createDirectory(at: destination.deletingLastPathComponent(),
                                    withIntermediateDirectories: true)
    try fileManager.moveItem(at: source, to: destination)
}

func remove(_ url: URL) throws {
    try fileManager.removeItem(at: url)
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("❌ \(message)\n").utf8))
    exit(1)
}

// MARK: - Argument parsing

/// A tiny `--flag value` argument lookup.
struct CommandLineArguments {
    private let values: [String: String]
    init(_ argv: [String]) {
        var map = [String: String]()
        var index = 1
        while index < argv.count {
            let token = argv[index]
            if token.hasPrefix("--"), index + 1 < argv.count, !argv[index + 1].hasPrefix("--") {
                map[token] = argv[index + 1]
                index += 2
            } else {
                index += 1
            }
        }
        values = map
    }
    subscript(_ key: String) -> String? { values[key] }
}
