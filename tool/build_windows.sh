#!/bin/bash
set -e

# Windows build using native compilation (faster than CMake)
echo "Building Windows binary with native compilation..."

# Use clang-cl for C/C++ compilation (much faster than MSVC cl.exe for massive files like sqlite3.c)
export CC_x86_64_pc_windows_msvc="clang-cl"
export CXX_x86_64_pc_windows_msvc="clang-cl"
export CC_aarch64_pc_windows_msvc="clang-cl"
export CXX_aarch64_pc_windows_msvc="clang-cl"

# Use lld-link for significantly faster linking, especially with LTO enabled
export RUSTFLAGS="-C linker=lld-link -C link-arg=/IGNORE:4099"

if [ "$1" = "x64" ]; then
  rustup target add x86_64-pc-windows-msvc
  cargo build -p isar --target x86_64-pc-windows-msvc --features sqlcipher-vendored --release
  cp "target/x86_64-pc-windows-msvc/release/isar.dll" "isar_windows_x64.dll"
  echo "✅ Windows x64 build completed (native compilation)"
else
  rustup target add aarch64-pc-windows-msvc
  cargo build -p isar --target aarch64-pc-windows-msvc --features sqlcipher-vendored --release
  cp "target/aarch64-pc-windows-msvc/release/isar.dll" "isar_windows_arm64.dll"
  echo "✅ Windows ARM64 build completed (native compilation)"
fi