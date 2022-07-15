// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TwilioVerifySNA",
    platforms: [
        .macOS(.v12),
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "TwilioVerifySNA",
            targets: [
                "TwilioVerifySNA",
                "SNANetworking"
            ]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TwilioVerifySNA",
            dependencies: ["SNANetworking"],
            path: "Sources",
            exclude: []
        ),
        .target(
            name: "SNANetworking",
            dependencies: [],
            path: "SNASources",
            exclude: []
        ),
        .testTarget(
            name: "TwilioVerifySNATests",
            dependencies: ["TwilioVerifySNA"],
            path: "Tests",
            exclude: []
        )
    ]
)
