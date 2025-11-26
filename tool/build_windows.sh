#!/bin/bash

# Windows build using native compilation (faster than CMake)
echo "Building Windows binary with native compilation..."

if [ "$1" = "x64" ]; then
  rustup target add x86_64-pc-windows-msvc
  cargo build --target x86_64-pc-windows-msvc --features sqlcipher-vendored --release
  cp "target/x86_64-pc-windows-msvc/release/isar.dll" "isar_windows_x64.dll"
  echo "✅ Windows x64 build completed (native compilation)"
else
  rustup target add aarch64-pc-windows-msvc
  cargo build --target aarch64-pc-windows-msvc --features sqlcipher-vendored --release
  cp "target/aarch64-pc-windows-msvc/release/isar.dll" "isar_windows_arm64.dll"
  echo "✅ Windows ARM64 build completed (native compilation)"
fi