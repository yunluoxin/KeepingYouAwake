// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KYACommon",
    platforms: [.macOS(.v11)],
    products: [.library(name: "KYACommon", targets: ["KYACommon"])],
    targets: [
        .target(name: "KYACommon"),
        .testTarget(name: "KYACommonTests", dependencies: ["KYACommon"]),
    ]
)