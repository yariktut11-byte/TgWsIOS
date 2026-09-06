// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TgWsIOS",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "TgWsProxy",
            targets: ["TgWsProxy"]
        ),
        .executable(
            name: "TgWsApp",
            targets: ["TgWsApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TgWsProxy",
            dependencies: []
        ),
        .executableTarget(
            name: "TgWsApp",
            dependencies: ["TgWsProxy"]
        ),
        .testTarget(
            name: "TgWsIOSTests",
            dependencies: ["TgWsProxy"]
        )
    ]
)
