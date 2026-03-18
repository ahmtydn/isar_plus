#!/bin/bash
set -e

# iOS + macOS XCFramework builder
# Prerequisites: build_ios.sh and build_macos.sh must be run first

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

echo "==> Checking iOS static libraries..."
if [[ ! -f "$REPO_ROOT/target/aarch64-apple-ios/release/libisar.a" ]]; then
    echo "Error: iOS arm64 library not found. Run build_ios.sh first."
    exit 1
fi

if [[ ! -f "$REPO_ROOT/target/aarch64-apple-ios-sim/release/libisar.a" ]]; then
    echo "Error: iOS simulator arm64 library not found. Run build_ios.sh first."
    exit 1
fi

if [[ ! -f "$REPO_ROOT/target/x86_64-apple-ios/release/libisar.a" ]]; then
    echo "Error: iOS simulator x86_64 library not found. Run build_ios.sh first."
    exit 1
fi

echo "==> Checking macOS static libraries..."
if [[ ! -f "$REPO_ROOT/target/aarch64-apple-darwin/release/libisar.a" ]]; then
    echo "Error: macOS arm64 library not found. Run build_macos.sh first."
    exit 1
fi

if [[ ! -f "$REPO_ROOT/target/x86_64-apple-darwin/release/libisar.a" ]]; then
    echo "Error: macOS x86_64 library not found. Run build_macos.sh first."
    exit 1
fi

echo "==> Creating iOS simulator universal binary..."
lipo "$REPO_ROOT/target/aarch64-apple-ios-sim/release/libisar.a" \
     "$REPO_ROOT/target/x86_64-apple-ios/release/libisar.a" \
     -output "$REPO_ROOT/target/libisar_ios_sim.a" -create

echo "==> Creating macOS universal binary..."
lipo "$REPO_ROOT/target/aarch64-apple-darwin/release/libisar.a" \
     "$REPO_ROOT/target/x86_64-apple-darwin/release/libisar.a" \
     -output "$REPO_ROOT/target/libisar_macos.a" -create

echo "==> Creating unified XCFramework (iOS device + iOS simulator + macOS)..."
rm -rf "$REPO_ROOT/isar.xcframework"
xcodebuild -create-xcframework \
    -library "$REPO_ROOT/target/aarch64-apple-ios/release/libisar.a" \
    -library "$REPO_ROOT/target/libisar_ios_sim.a" \
    -library "$REPO_ROOT/target/libisar_macos.a" \
    -output "$REPO_ROOT/isar.xcframework"

echo "==> Creating archive..."
cd "$REPO_ROOT"
zip -r isar.xcframework.zip isar.xcframework

echo "==> Done! isar.xcframework contains:"
ls -1 "$REPO_ROOT/isar.xcframework/" | grep -v Info.plist
echo ""
echo "Archive: isar.xcframework.zip"
