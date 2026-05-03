#!/bin/bash
set -e

export IPHONEOS_DEPLOYMENT_TARGET=11.0
export MACOSX_DEPLOYMENT_TARGET=10.13

# Add all required targets
echo "Adding Darwin targets..."
rustup target add \
    aarch64-apple-ios \
    aarch64-apple-ios-sim \
    x86_64-apple-ios \
    aarch64-apple-darwin \
    x86_64-apple-darwin

# iOS device
echo "Building for aarch64-apple-ios..."
cargo build -p isar --target aarch64-apple-ios --features sqlcipher --release

# iOS simulator — create universal binary
echo "Building for aarch64-apple-ios-sim..."
cargo build -p isar --target aarch64-apple-ios-sim --features sqlcipher --release

echo "Building for x86_64-apple-ios..."
cargo build -p isar --target x86_64-apple-ios --features sqlcipher --release

echo "Creating universal iOS simulator binary..."
mkdir -p build/ios-simulator
lipo target/aarch64-apple-ios-sim/release/libisar.a \
     target/x86_64-apple-ios/release/libisar.a \
     -output build/ios-simulator/libisar.a -create

# macOS — create universal static binary
echo "Building for aarch64-apple-darwin..."
cargo build -p isar --target aarch64-apple-darwin --features sqlcipher --release

echo "Building for x86_64-apple-darwin..."
cargo build -p isar --target x86_64-apple-darwin --features sqlcipher --release

echo "Creating universal macOS binary..."
mkdir -p build/macos
lipo target/aarch64-apple-darwin/release/libisar.a \
     target/x86_64-apple-darwin/release/libisar.a \
     -output build/macos/libisar.a -create

# Assemble unified XCFramework
echo "Assembling IsarPlusCore.xcframework..."
xcodebuild -create-xcframework \
    -library target/aarch64-apple-ios/release/libisar.a \
    -library build/ios-simulator/libisar.a \
    -library build/macos/libisar.a \
    -output IsarPlusCore.xcframework

echo "Creating archive..."
zip -r IsarPlusCore.xcframework.zip IsarPlusCore.xcframework

echo "Computing checksum..."
shasum -a 256 IsarPlusCore.xcframework.zip | awk '{print $1}' > IsarPlusCore.xcframework.zip.sha256
echo "Checksum: $(cat IsarPlusCore.xcframework.zip.sha256)"
