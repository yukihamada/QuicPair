// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "QuicPair",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "QuicPair",
            targets: ["QuicPair"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "QuicPair",
            path: "QuicPair",
            resources: [
                .process("Resources")
            ]
        )
    ]
)