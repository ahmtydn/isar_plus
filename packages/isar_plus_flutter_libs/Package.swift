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
            name: "isar_plus_flutter_libs",
            targets: ["isar_plus_flutter_libs"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "IsarPlusCore",
            url: "https://github.com/ahmtydn/isar/releases/download/<VERSION>/IsarPlusCore.xcframework.zip",
            checksum: "<CHECKSUM>"
        ),
        .target(
            name: "isar_plus_flutter_libs",
            dependencies: ["IsarPlusCore"],
            path: "darwin/Classes",
            publicHeadersPath: "."
        ),
    ]
)
