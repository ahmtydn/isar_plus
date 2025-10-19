#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: prepare_local_dev.sh [options]

Build Isar Plus artifacts locally and wire the example app to use them.

Options:
  --targets <list>   Comma separated list of targets to build
                     (default: macos,ios,wasm).
                     Supported values: macos,ios,wasm,android-arm64,android-armv7,android-x64,linux-x64,windows-x64.
  --version <ver>    Version string to export as ISAR_VERSION (default: 0.0.0-local).
  --example <name>   Example directory under examples/ to wire up (default: counter).
  --skip-pub-get     Skip running pub get / flutter pub get at the end.
  -h, --help         Show this help message.
EOF
}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
TARGETS=(macos ios wasm)
VERSION="0.0.0-local"
EXAMPLE="counter"
RUN_PUB_GET=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --targets)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --targets" >&2
        exit 1
      fi
      IFS=',' read -r -a TARGETS <<<"$2"
      shift 2
      ;;
    --version)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --version" >&2
        exit 1
      fi
      VERSION="$2"
      shift 2
      ;;
    --example)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --example" >&2
        exit 1
      fi
      EXAMPLE="$2"
      shift 2
      ;;
    --skip-pub-get)
      RUN_PUB_GET=false
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

EXAMPLE_DIR="$REPO_ROOT/examples/$EXAMPLE"

has_target() {
  local needle="$1"
  for t in "${TARGETS[@]}"; do
    if [[ "$t" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

export ISAR_VERSION="$VERSION"
echo "Preparing local Isar Plus artifacts for targets: ${TARGETS[*]}"

# Clean existing build artifacts before building
echo "\n==> Cleaning existing build artifacts"
rm -f "$REPO_ROOT/libisar_macos.dylib"
rm -f "$REPO_ROOT/isar_ios.xcframework.zip"
rm -rf "$REPO_ROOT/isar.xcframework"
rm -f "$REPO_ROOT/isar.wasm"
rm -f "$REPO_ROOT/isar.js"
rm -f "$REPO_ROOT/libisar_android_arm64.so"
rm -f "$REPO_ROOT/libisar_android_armv7.so"
rm -f "$REPO_ROOT/libisar_android_x64.so"
rm -f "$REPO_ROOT/libisar_linux_x64.so"
rm -f "$REPO_ROOT/isar_windows_x64.dll"
rm -f "$EXAMPLE_DIR/web/isar.wasm"
rm -f "$EXAMPLE_DIR/web/isar.js"
echo "Build artifacts cleaned"

declare -a built_artifacts=()

if has_target "macos"; then
  echo "\n==> Building macOS universal dylib"
  bash "$SCRIPT_DIR/build_macos.sh"
  mkdir -p "$REPO_ROOT/packages/isar_plus_flutter_libs/macos"
  cp "$REPO_ROOT/libisar_macos.dylib" "$REPO_ROOT/packages/isar_plus_flutter_libs/macos/libisar.dylib"
  built_artifacts+=("macos dylib -> packages/isar_plus_flutter_libs/macos/libisar.dylib")
fi

if has_target "ios"; then
  echo "\n==> Building iOS xcframework"
  bash "$SCRIPT_DIR/build_ios.sh"
  IOS_DIR="$REPO_ROOT/packages/isar_plus_flutter_libs/ios"
  rm -rf "$IOS_DIR/isar.xcframework"
  unzip -qo "$REPO_ROOT/isar_ios.xcframework.zip" -d "$IOS_DIR"
  built_artifacts+=("ios xcframework -> packages/isar_plus_flutter_libs/ios/isar.xcframework")
fi

if has_target "wasm"; then
  echo "\n==> Building WebAssembly bundle"
  bash "$SCRIPT_DIR/build_wasm.sh"
  mkdir -p "$EXAMPLE_DIR/web"
  cp "$REPO_ROOT/isar.wasm" "$EXAMPLE_DIR/web/isar.wasm"
  cp "$REPO_ROOT/isar.js" "$EXAMPLE_DIR/web/isar.js"
  built_artifacts+=("web wasm -> isar.wasm and isar.js")
fi

ANDROID_LIB_DIR="$REPO_ROOT/packages/isar_plus_flutter_libs/android/src/main/jniLibs"
if has_target "android-arm64"; then
  echo "\n==> Building Android ARM64"
  bash "$SCRIPT_DIR/build_android.sh"
  mkdir -p "$ANDROID_LIB_DIR/arm64-v8a"
  cp "$REPO_ROOT/libisar_android_arm64.so" "$ANDROID_LIB_DIR/arm64-v8a/libisar.so"
  built_artifacts+=("android arm64 -> .../jniLibs/arm64-v8a/libisar.so")
fi

if has_target "android-armv7"; then
  echo "\n==> Building Android ARMv7"
  bash "$SCRIPT_DIR/build_android.sh" armv7
  mkdir -p "$ANDROID_LIB_DIR/armeabi-v7a"
  cp "$REPO_ROOT/libisar_android_armv7.so" "$ANDROID_LIB_DIR/armeabi-v7a/libisar.so"
  built_artifacts+=("android armv7 -> .../jniLibs/armeabi-v7a/libisar.so")
fi

if has_target "android-x64"; then
  echo "\n==> Building Android x64"
  bash "$SCRIPT_DIR/build_android.sh" x64
  mkdir -p "$ANDROID_LIB_DIR/x86_64"
  cp "$REPO_ROOT/libisar_android_x64.so" "$ANDROID_LIB_DIR/x86_64/libisar.so"
  built_artifacts+=("android x64 -> .../jniLibs/x86_64/libisar.so")
fi

if has_target "linux-x64"; then
  echo "\n==> Building Linux x64"
  bash "$SCRIPT_DIR/build_linux.sh" x64
  mkdir -p "$REPO_ROOT/packages/isar_plus_flutter_libs/linux"
  cp "$REPO_ROOT/libisar_linux_x64.so" "$REPO_ROOT/packages/isar_plus_flutter_libs/linux/libisar.so"
  built_artifacts+=("linux x64 -> packages/isar_plus_flutter_libs/linux/libisar.so")
fi

if has_target "windows-x64"; then
  echo "\n==> Building Windows x64"
  bash "$SCRIPT_DIR/build_windows.sh" x64
  mkdir -p "$REPO_ROOT/packages/isar_plus_flutter_libs/windows"
  cp "$REPO_ROOT/isar_windows_x64.dll" "$REPO_ROOT/packages/isar_plus_flutter_libs/windows/isar.dll"
  built_artifacts+=("windows x64 -> packages/isar_plus_flutter_libs/windows/isar.dll")
fi

if [[ ! -d "$EXAMPLE_DIR" ]]; then
  echo "Example directory not found: $EXAMPLE_DIR" >&2
  exit 1
fi

echo "\n==> Creating pubspec_overrides.yaml for example: $EXAMPLE"
mkdir -p "$EXAMPLE_DIR"
cat >"$EXAMPLE_DIR/pubspec_overrides.yaml" <<'YAML'
dependency_overrides:
  isar_plus:
    path: ../../packages/isar_plus
  isar_plus_flutter_libs:
    path: ../../packages/isar_plus_flutter_libs
YAML

if [[ "$RUN_PUB_GET" == true ]]; then
  echo "\n==> Running pub get in local packages"
  (cd "$REPO_ROOT/packages/isar_plus" && dart pub get)
  (cd "$REPO_ROOT/packages/isar_plus_flutter_libs" && flutter pub get)
  (cd "$EXAMPLE_DIR" && flutter pub get)
fi

echo "\n==> Summary"
printf '  - %s\n' "${built_artifacts[@]}"
cat <<EOF

Local environment prepared. You can now run the example with:
  cd "$EXAMPLE_DIR"
  flutter run -d macos
EOF
