// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "isar_plus_flutter_libs",
    platforms: [
        .iOS("12.0"),
        .macOS("10.15")
    ],
    products: [
        .library(
            name: "isar-plus-flutter-libs",
            targets: ["isar_plus_flutter_libs"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "isar_plus_flutter_libs",
            dependencies: ["isar"]
        ),
        .binaryTarget(
            name: "isar",
            path: "isar.xcframework"
        )
    ]
)
