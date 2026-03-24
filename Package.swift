// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "JikanSwift",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "JikanSwift",
            targets: ["JikanSwift"]
        )
    ],
    targets: [
        .target(
            name: "JikanSwift",
            path: "Sources/JikanSwift"
        ),
        .testTarget(
            name: "JikanSwiftTests",
            dependencies: ["JikanSwift"],
            path: "Tests/JikanSwiftTests",
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
