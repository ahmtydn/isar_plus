#!/bin/bash

if [[ "$(uname -s)" == "Darwin" ]]; then
    export NDK_HOST_TAG="darwin-x86_64"
elif [[ "$(uname -s)" == "Linux" ]]; then
    export NDK_HOST_TAG="linux-x86_64"
else
    echo "Unsupported OS."
    exit
fi

NDK=${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-"$ANDROID_SDK_ROOT/ndk"}}

# Find the actual NDK directory if using SDK root
if [[ "$NDK" == *"/ndk" ]] && [[ ! -d "$NDK/toolchains" ]]; then
    # Find the latest NDK version
    NDK_VERSION=$(ls "$NDK" | grep -E '^[0-9]+\.' | sort -V | tail -n 1)
    if [[ -n "$NDK_VERSION" ]]; then
        NDK="$NDK/$NDK_VERSION"
    fi
fi

COMPILER_DIR="$NDK/toolchains/llvm/prebuilt/$NDK_HOST_TAG/bin"
RUNTIME_LIB_DIR="$NDK/toolchains/llvm/prebuilt/$NDK_HOST_TAG/lib/clang"

# Find clang version for runtime libs
CLANG_VERSION=$(ls "$RUNTIME_LIB_DIR" | head -n 1)
RUNTIME_LIB_PATH="$RUNTIME_LIB_DIR/$CLANG_VERSION/lib/linux"

export PATH="$COMPILER_DIR:$PATH"

echo "NDK path: $NDK"
echo "Compiler dir: $COMPILER_DIR"
echo "Runtime lib path: $RUNTIME_LIB_PATH"
echo "Clang version: $CLANG_VERSION"

export CC_x86_64_linux_android=$COMPILER_DIR/x86_64-linux-android21-clang
export AR_x86_64_linux_android=$COMPILER_DIR/llvm-ar
export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER=$COMPILER_DIR/x86_64-linux-android21-clang
export CARGO_TARGET_X86_64_LINUX_ANDROID_AR=$COMPILER_DIR/llvm-ar
export CARGO_TARGET_X86_64_LINUX_ANDROID_RUSTFLAGS="-L $RUNTIME_LIB_PATH"
ln -s "$AR_x86_64_linux_android" "$COMPILER_DIR/x86_64-linux-android-ranlib"

export CC_armv7_linux_androideabi=$COMPILER_DIR/armv7a-linux-androideabi21-clang
export AR_armv7_linux_androideabi=$COMPILER_DIR/llvm-ar
export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER=$COMPILER_DIR/armv7a-linux-androideabi21-clang
export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_AR=$COMPILER_DIR/llvm-ar
export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_RUSTFLAGS="-L $RUNTIME_LIB_PATH"
ln -s "$AR_armv7_linux_androideabi" "$COMPILER_DIR/arm-linux-androideabi-ranlib"

export CC_aarch64_linux_android=$COMPILER_DIR/aarch64-linux-android21-clang
export AR_aarch64_linux_android=$COMPILER_DIR/llvm-ar
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=$COMPILER_DIR/aarch64-linux-android21-clang
export CARGO_TARGET_AARCH64_LINUX_ANDROID_AR=$COMPILER_DIR/llvm-ar
export CARGO_TARGET_AARCH64_LINUX_ANDROID_RUSTFLAGS="-L $RUNTIME_LIB_PATH"
ln -s "$AR_aarch64_linux_android" "$COMPILER_DIR/aarch64-linux-android-ranlib"

cd packages/isar_core_ffi

if [ "$1" = "x64" ]; then
  rustup target add x86_64-linux-android
  cargo build --target x86_64-linux-android --features sqlcipher-vendored --release
  cp "../../target/x86_64-linux-android/release/libisar.so" "../../libisar_android_x64.so"
elif [ "$1" = "armv7" ]; then
  rustup target add armv7-linux-androideabi
  cargo build --target armv7-linux-androideabi --features sqlcipher-vendored --release
  cp "../../target/armv7-linux-androideabi/release/libisar.so" "../../libisar_android_armv7.so"
else
  rustup target add aarch64-linux-android
  cargo build --target aarch64-linux-android --features sqlcipher-vendored --release
  cp "../../target/aarch64-linux-android/release/libisar.so" "../../libisar_android_arm64.so"
fi






