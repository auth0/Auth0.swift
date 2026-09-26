// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DocsVersions",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "DocsVersions",
            path: "Sources/DocsVersions",
            resources: [.copy("Resources/version-selector.js")]
        ),
        .testTarget(
            name: "DocsVersionsTests",
            dependencies: ["DocsVersions"],
            path: "Tests/DocsVersionsTests"
        )
    ]
)
