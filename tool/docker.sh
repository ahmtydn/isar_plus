#!/bin/bash
set -e

# Configuration
IMAGE_NAME="isar-plus-coverage"
CONTAINER_NAME="isar-plus-coverage-run"
REPORT_DIR="coverage_report"

echo "==> Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME -f tool/Dockerfile.coverage .

echo "==> Running coverage inside Docker"
# We mount the current directory to /app
# We use a script inside the container to perform the steps
docker run --rm \
    -v "$(pwd):/app" \
    --name $CONTAINER_NAME \
    $IMAGE_NAME \
    /bin/bash -c "
        set -e
        echo '==> [Inside Docker] Preparing environment'
        sh tool/build.sh
        bash tool/build_wasm.sh
        sh tool/prepare_tests.sh

        echo '==> [Inside Docker] Collecting Core (Rust) Coverage'
        cargo tarpaulin --workspace -o Lcov --engine llvm
        mv lcov.info lcov_core.info

        echo '==> [Inside Docker] Collecting Dart Native Coverage'
        cd packages/isar_plus
        flutter pub add json_annotation || true
        echo "" >> pubspec.yaml
        echo "dependency_overrides:" >> pubspec.yaml
        echo "  isar_plus_flutter_libs:" >> pubspec.yaml
        echo "    path: ../isar_plus_flutter_libs" >> pubspec.yaml
        flutter pub add isar_plus_test --path ../isar_plus_test || true
        flutter pub get
        flutter test --coverage ../isar_plus_test/test --coverage-path lcov_isar_plus_test.info
        cd ../..

        echo '==> [Inside Docker] Collecting Dart Web Coverage'
        cd packages/isar_plus_test
        npx --yes serve --cors -p 3000 &
        SLEEP_PID=\$!
        sleep 5
        dart test --coverage=coverage_web -p chrome -j 1 --timeout 300s test/all_tests.dart || true
        kill \$SLEEP_PID || true
        
        if [ -d 'coverage_web' ]; then
            dart pub global activate coverage
            export PATH=\"\$PATH:\$HOME/.pub-cache/bin\"
            format_coverage \
                --lcov \
                --in=coverage_web \
                --out=../isar_plus/lcov_isar_plus_test_web.info \
                --report-on=../isar_plus/lib \
                --packages=.dart_tool/package_config.json || true
            rm -rf coverage_web
        fi
        cd ../..

        echo '==> [Inside Docker] Merging Coverage Reports'
        # Collect all .info files
        LCOV_INPUTS=\"\"
        [ -f lcov_core.info ] && LCOV_INPUTS=\"\$LCOV_INPUTS -a lcov_core.info\"
        [ -f packages/isar_plus/lcov_isar_plus_test.info ] && LCOV_INPUTS=\"\$LCOV_INPUTS -a packages/isar_plus/lcov_isar_plus_test.info\"
        [ -f packages/isar_plus/lcov_isar_plus_test_web.info ] && LCOV_INPUTS=\"\$LCOV_INPUTS -a packages/isar_plus/lcov_isar_plus_test_web.info\"

        if [ -n \"\$LCOV_INPUTS\" ]; then
            lcov \$LCOV_INPUTS -o combined_lcov.info
            # Filter out generated files and tests
            lcov --remove combined_lcov.info '*/generated/*' '*/test/*' '*/.dart_tool/*' -o filtered_lcov.info
            
            echo '==> [Inside Docker] Generating HTML report'
            rm -rf $REPORT_DIR
            genhtml filtered_lcov.info -o $REPORT_DIR
            echo '==> [Inside Docker] Coverage report generated in $REPORT_DIR'
        else
            echo 'Error: No coverage data found!'
            exit 1
        fi
    "

echo ""
echo "==========================================================="
echo "Coverage process finished!"
echo "You can view the report by opening: $REPORT_DIR/index.html"
echo "==========================================================="
