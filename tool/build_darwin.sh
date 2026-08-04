#!/bin/bash
set -euo pipefail

export IPHONEOS_DEPLOYMENT_TARGET=11.0
export MACOSX_DEPLOYMENT_TARGET=10.13

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
cd "$REPO_ROOT"

FRAMEWORK_NAME="IsarPlusCore"
BUNDLE_ID="dev.isar.IsarPlusCore"
BUILD_DIR="$REPO_ROOT/build/darwin"

BUNDLE_VERSION=$(printf '%s' "${ISAR_VERSION:-0.0.0}" | sed 's/^v//' | grep -oE '^[0-9]+(\.[0-9]+){0,2}' || true)
BUNDLE_VERSION=${BUNDLE_VERSION:-0.0.0}

TARGETS=(
  aarch64-apple-ios
  aarch64-apple-ios-sim
  x86_64-apple-ios
  aarch64-apple-darwin
  x86_64-apple-darwin
)

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Adding Darwin targets..."
rustup target add "${TARGETS[@]}"

for triple in "${TARGETS[@]}"; do
  echo "Building for $triple..."
  cargo build -p isar-plus --target "$triple" --features sqlcipher --release
done

dylib_for() {
  echo "$REPO_ROOT/target/$1/release/libisar_plus.dylib"
}

# write_info_plist <path> <platform> <min_os_key> <min_os_version>
write_info_plist() {
  local path=$1 platform=$2 min_os_key=$3 min_os_version=$4
  cat >"$path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>$FRAMEWORK_NAME</string>
	<key>CFBundleIdentifier</key>
	<string>$BUNDLE_ID</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$FRAMEWORK_NAME</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>$BUNDLE_VERSION</string>
	<key>CFBundleVersion</key>
	<string>$BUNDLE_VERSION</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>$platform</string>
	</array>
	<key>$min_os_key</key>
	<string>$min_os_version</string>
</dict>
</plist>
PLIST
}

# make_flat_framework <out_dir> <fat_dylib> <platform>
# iOS/tvOS style: a flat bundle with the binary at the top level.
make_flat_framework() {
  local out_dir=$1 dylib=$2 platform=$3
  local fw="$out_dir/$FRAMEWORK_NAME.framework"

  rm -rf "$fw"
  mkdir -p "$fw"
  cp "$dylib" "$fw/$FRAMEWORK_NAME"
  chmod +x "$fw/$FRAMEWORK_NAME"
  install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" \
    "$fw/$FRAMEWORK_NAME"
  write_info_plist "$fw/Info.plist" "$platform" MinimumOSVersion \
    "$IPHONEOS_DEPLOYMENT_TARGET"
  echo "$fw"
}

# make_versioned_framework <out_dir> <fat_dylib>
# macOS requires the versioned bundle layout with Current/ symlinks.
make_versioned_framework() {
  local out_dir=$1 dylib=$2
  local fw="$out_dir/$FRAMEWORK_NAME.framework"

  rm -rf "$fw"
  mkdir -p "$fw/Versions/A/Resources"
  cp "$dylib" "$fw/Versions/A/$FRAMEWORK_NAME"
  chmod +x "$fw/Versions/A/$FRAMEWORK_NAME"
  install_name_tool \
    -id "@rpath/$FRAMEWORK_NAME.framework/Versions/A/$FRAMEWORK_NAME" \
    "$fw/Versions/A/$FRAMEWORK_NAME"
  write_info_plist "$fw/Versions/A/Resources/Info.plist" MacOSX \
    LSMinimumSystemVersion "$MACOSX_DEPLOYMENT_TARGET"
  ln -s A "$fw/Versions/Current"
  ln -s "Versions/Current/$FRAMEWORK_NAME" "$fw/$FRAMEWORK_NAME"
  ln -s Versions/Current/Resources "$fw/Resources"
  echo "$fw"
}

echo "Creating universal iOS simulator binary..."
mkdir -p "$BUILD_DIR/ios-simulator"
lipo -create \
  "$(dylib_for aarch64-apple-ios-sim)" \
  "$(dylib_for x86_64-apple-ios)" \
  -output "$BUILD_DIR/ios-simulator/libisar_plus.dylib"

echo "Creating universal macOS binary..."
mkdir -p "$BUILD_DIR/macos"
lipo -create \
  "$(dylib_for aarch64-apple-darwin)" \
  "$(dylib_for x86_64-apple-darwin)" \
  -output "$BUILD_DIR/macos/libisar_plus.dylib"

echo "Assembling $FRAMEWORK_NAME.framework bundles..."
mkdir -p "$BUILD_DIR/ios" "$BUILD_DIR/ios-sim-fw" "$BUILD_DIR/macos-fw"
IOS_FW=$(make_flat_framework "$BUILD_DIR/ios" "$(dylib_for aarch64-apple-ios)" iPhoneOS)
SIM_FW=$(make_flat_framework "$BUILD_DIR/ios-sim-fw" "$BUILD_DIR/ios-simulator/libisar_plus.dylib" iPhoneSimulator)
MAC_FW=$(make_versioned_framework "$BUILD_DIR/macos-fw" "$BUILD_DIR/macos/libisar_plus.dylib")

echo "Assembling isar_plus_core.xcframework..."
rm -rf isar_plus_core.xcframework isar_plus_core.xcframework.zip
xcodebuild -create-xcframework \
  -framework "$IOS_FW" \
  -framework "$SIM_FW" \
  -framework "$MAC_FW" \
  -output isar_plus_core.xcframework

echo "Verifying exported symbols..."
for slice in isar_plus_core.xcframework/*/"$FRAMEWORK_NAME".framework; do
  binary="$slice/$FRAMEWORK_NAME"
  [[ -f "$binary" ]] || binary="$slice/Versions/A/$FRAMEWORK_NAME"
  count=$(nm -gU "$binary" 2>/dev/null | grep -c ' T _isar_plus_' || true)
  if [[ "$count" -lt 1 ]] || ! nm -gU "$binary" 2>/dev/null | grep -q ' T _isar_plus_version$'; then
    echo "ERROR: $binary does not export isar_plus_version (found $count isar_plus symbols)" >&2
    exit 1
  fi
  echo "  $(basename "$(dirname "$slice")"): $count exported isar_plus symbols"
done

echo "Creating archive..."
zip -qry isar_plus_core.xcframework.zip isar_plus_core.xcframework

echo "Computing checksum..."
shasum -a 256 isar_plus_core.xcframework.zip | awk '{print $1}' > isar_plus_core.xcframework.zip.sha256
echo "Checksum: $(cat isar_plus_core.xcframework.zip.sha256)"
