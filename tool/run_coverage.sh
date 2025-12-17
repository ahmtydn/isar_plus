#!/bin/bash
set -e

# --- Configuration ---
ISAR_PLUS_DIR="packages/isar_plus"
ISAR_PLUS_TEST_DIR="packages/isar_plus_test"
COVERAGE_DIR="coverage"
LCOV_INFO_NATIVE="$ISAR_PLUS_DIR/lcov_isar_plus_test.info"
LCOV_INFO_WEB="$ISAR_PLUS_DIR/lcov_isar_plus_test_web.info"
MERGED_LCOV="lcov.info"

# --- Helper Functions ---
function cleanup {
  echo "Cleaning up..."
  if [ -f "$ISAR_PLUS_DIR/pubspec.yaml.bak" ]; then
    mv "$ISAR_PLUS_DIR/pubspec.yaml.bak" "$ISAR_PLUS_DIR/pubspec.yaml"
    echo "Restored pubspec.yaml"
  fi
  # Kill any background serve processes
  pkill -f "serve --cors" || true
}

trap cleanup EXIT

# --- Check Dependencies ---
command -v flutter >/dev/null 2>&1 || { echo >&2 "Flutter is required but not installed. Aborting."; exit 1; }
command -v dart >/dev/null 2>&1 || { echo >&2 "Dart is required but not installed. Aborting."; exit 1; }
command -v lcov >/dev/null 2>&1 || { echo >&2 "lcov is required but not installed. Aborting."; exit 1; }

# --- Build Core ---
echo "Building Isar Core (Native)..."
sh tool/build.sh

echo "Building Isar Core (WASM)..."
bash tool/build_wasm.sh

# --- Prepare Tests ---
echo "Preparing Tests..."
sh tool/prepare_tests.sh

# --- Modify pubspec.yaml for Testing ---
echo "Modifying isar_plus/pubspec.yaml for tests..."
cp "$ISAR_PLUS_DIR/pubspec.yaml" "$ISAR_PLUS_DIR/pubspec.yaml.bak"

# Add temporary dependencies
cd "$ISAR_PLUS_DIR"
flutter pub add json_annotation
echo "" >> pubspec.yaml
echo "dependency_overrides:" >> pubspec.yaml
echo "  isar_plus_flutter_libs:" >> pubspec.yaml
echo "    path: ../isar_plus_flutter_libs" >> pubspec.yaml
flutter pub add isar_plus_test --path ../isar_plus_test
flutter pub get
cd ../..

# --- Run Native Tests with Coverage ---
echo "Running Native Tests..."
cd "$ISAR_PLUS_DIR"
# Run tests in isar_plus_test but collect coverage for isar_plus
flutter test --coverage ../isar_plus_test/test --coverage-path lcov_isar_plus_test.info
cd ../..

# --- Run Web Tests with Coverage ---
echo "Running Web Tests..."
# Start minimal web server for wasm
npx --yes serve --cors -p 3000 &
SERVER_PID=$!
sleep 5 # Wait for server to start

cd "$ISAR_PLUS_TEST_DIR"
rm -rf coverage_web
# Run tests with chrome driver
dart test --coverage=coverage_web -p chrome -j 1 --timeout 300s test/all_tests.dart || true

if [ -d "coverage_web" ]; then
  dart pub global activate coverage
  dart pub global run coverage:format_coverage \
    --lcov \
    --in=coverage_web \
    --out=../isar_plus/lcov_isar_plus_test_web.info \
    --report-on=../isar_plus/lib \
    --packages=.dart_tool/package_config.json || true
  rm -rf coverage_web
fi
cd ../..

# --- Combine Coverage ---
echo "Combining Coverage Reports..."
cd "$ISAR_PLUS_DIR"
lcov_args=""
if [ -f "lcov_isar_plus_test.info" ]; then
  lcov_args="$lcov_args -a lcov_isar_plus_test.info"
fi
if [ -f "lcov_isar_plus_test_web.info" ]; then
  lcov_args="$lcov_args -a lcov_isar_plus_test_web.info"
fi

if [ -n "$lcov_args" ]; then
  mkdir -p "$COVERAGE_DIR"
  lcov $lcov_args -o "$MERGED_LCOV"
  
  # Generate HTML report
  genhtml "$MERGED_LCOV" -o "$COVERAGE_DIR"
  echo "Coverage report generated at $ISAR_PLUS_DIR/$COVERAGE_DIR/index.html"
else
  echo "No coverage data found!"
fi
cd ../..

echo "Done!"
