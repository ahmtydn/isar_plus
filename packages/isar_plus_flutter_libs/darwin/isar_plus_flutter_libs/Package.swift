// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "isar_plus_flutter_libs",
    platforms: [
        .iOS(.v11),
        .macOS(.v10_13),
    ],
    products: [
        .library(
            name: "isar-plus-flutter-libs",
            targets: ["isar_plus_flutter_libs"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "IsarPlusCore",
            path: "Core/IsarPlusCore.xcframework"
        ),
        .target(
            name: "CIsarCore",
            dependencies: ["IsarPlusCore"],
            path: "Core"
        ),
        .target(
            name: "isar_plus_flutter_libs",
            dependencies: ["CIsarCore"],
            path: "Plugin"
        ),
    ]
)
