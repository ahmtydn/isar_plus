#!/bin/bash
set -e

export IPHONEOS_DEPLOYMENT_TARGET=11.0

echo "Adding iOS targets..."
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios

echo "Building for aarch64-apple-ios..."
cargo build --target aarch64-apple-ios --features sqlcipher --release

echo "Building for aarch64-apple-ios-sim..."
cargo build --target aarch64-apple-ios-sim --features sqlcipher --release

echo "Building for x86_64-apple-ios..."
cargo build --target x86_64-apple-ios --features sqlcipher --release

# Check if all required libraries exist before creating the universal binary
if [[ ! -f "target/aarch64-apple-ios-sim/release/libisar.a" ]]; then
    echo "Error: aarch64-apple-ios-sim library not found"
    exit 1
fi

if [[ ! -f "target/x86_64-apple-ios/release/libisar.a" ]]; then
    echo "Error: x86_64-apple-ios library not found"
    exit 1
fi

if [[ ! -f "target/aarch64-apple-ios/release/libisar.a" ]]; then
    echo "Error: aarch64-apple-ios library not found"
    exit 1
fi

echo "Creating universal simulator binary..."
lipo "target/aarch64-apple-ios-sim/release/libisar.a" "target/x86_64-apple-ios/release/libisar.a" -output "target/aarch64-apple-ios-sim/libisar.a" -create

echo "Creating XCFramework..."
xcodebuild \
    -create-xcframework \
    -library target/aarch64-apple-ios/release/libisar.a \
    -library target/aarch64-apple-ios-sim/libisar.a \
    -output isar.xcframework 

echo "Creating archive..."
zip -r isar_ios.xcframework.zip isar.xcframework