// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "Auth0",
    // platforms: [.iOS("8.0"), .macOS("10.10"), .tvOS("9.0"), .watchOS("2.0")],
    products: [
        .library(name: "Auth0", targets: ["Auth0"])
    ],
    dependencies: [
        .package(url: "https://github.com/auth0/SimpleKeychain.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "Auth0",
            dependencies: ["SimpleKeychain"],
            path: "App"
        )
    ]
)
