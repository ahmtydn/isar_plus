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
        // IsarPlusCore.framework is a *dynamic* framework, so its exported
        // symbols survive `xcodebuild archive` and stay resolvable from Dart.
        // Xcode embeds and signs it into the host app's Frameworks directory.
        .binaryTarget(
            name: "isar_plus_core",
            url: "https://github.com/ahmtydn/isar_plus/releases/download/0.0.0-placeholder/isar_plus_core.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        ),
        // Exposes the few Core entry points the plugin itself calls to Swift.
        // The full FFI surface is bound from Dart, not from here.
        .target(
            name: "CIsarCore",
            dependencies: ["isar_plus_core"],
            path: "Core",
            publicHeadersPath: "include"
        ),
        .target(
            name: "isar_plus_flutter_libs",
            dependencies: ["CIsarCore"],
            path: "Plugin"
        ),
    ]
)
