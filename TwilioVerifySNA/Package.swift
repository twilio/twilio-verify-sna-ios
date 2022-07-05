// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TwilioVerifySNA",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "TwilioVerifySNA",
            targets: ["TwilioVerifySNA"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TwilioVerifySNA",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "TwilioVerifySNATests",
            dependencies: ["TwilioVerifySNA"],
            path: "Tests"
        ),
    ]
)
