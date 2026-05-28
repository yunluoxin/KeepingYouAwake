// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "KYASleepWakeTimer",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "KYASleepWakeTimer", targets: ["KYASleepWakeTimer"]),
    ],
    dependencies: [
        .package(name: "KYACommon", path: "../KYACommon"),
        .package(name: "KYAApplicationSupport", path: "../KYAApplicationSupport"),
    ],
    targets: [
        .target(
            name: "KYASleepWakeTimer",
            dependencies: [
                .product(name: "KYACommon", package: "KYACommon"),
                .product(name: "KYAApplicationSupport", package: "KYAApplicationSupport"),
            ]
        ),
        .testTarget(
            name: "KYASleepWakeTimerTests",
            dependencies: ["KYASleepWakeTimer"]
        ),
    ]
)