// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "KYADeviceInfo",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "KYADeviceInfo", targets: ["KYADeviceInfo"]),
    ],
    dependencies: [],
    targets: [
        // C shim for libproc functions (proc_listallpids, proc_pidpath)
        .target(
            name: "ClibprocShim",
            dependencies: []
        ),
        .target(
            name: "KYADeviceInfo",
            dependencies: [
                "ClibprocShim",
            ]
        ),
        .testTarget(
            name: "KYADeviceInfoTests",
            dependencies: ["KYADeviceInfo"]
        ),
    ]
)