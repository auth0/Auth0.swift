// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Auth0",
    platforms: [.iOS(.v9), .macOS(.v10_11), .tvOS(.v9), .watchOS(.v2)],
    products: [.library(name: "Auth0", targets: ["Auth0"])],
    dependencies: [
        .package(url: "https://github.com/auth0/SimpleKeychain.git", .upToNextMajor(from: "0.11.0")),
        .package(url: "https://github.com/auth0/JWTDecode.swift.git", .upToNextMajor(from: "2.4.0"))
    ],
    targets: [
        .target(
            name: "Auth0", 
            dependencies: ["SimpleKeychain", "JWTDecode", "Auth0ObjectiveC"], 
            path: "Auth0",
            exclude: ["ObjectiveC"],
            cSettings: [
                .define("WEBAUTH_PLATFORM", .when(platforms: [.iOS, .macOS]))
            ]),
        .target(name: "Auth0ObjectiveC", path: "Auth0/ObjectiveC")
    ]
)
