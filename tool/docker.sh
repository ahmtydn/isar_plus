#!/bin/bash
set -e

# Configuration
IMAGE_NAME="isar-plus-coverage"
CONTAINER_NAME="isar-plus-coverage-run"
REPORT_DIR="coverage_report"

echo "==> Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME -f tool/Dockerfile .

echo "==> Running coverage inside Docker"
# We mount the current directory to /app
# We use a script inside the container to perform the steps
docker run --rm \
    -v "$(pwd):/app" \
    --name $CONTAINER_NAME \
    $IMAGE_NAME \
    /bin/bash -c "
        set -e
        REPORT_DIR=\"$REPORT_DIR\"
        echo '==> [Inside Docker] Preparing environment'
        export CARGO_TARGET_DIR=/app/target_docker
        
        # Cross-architecture fix: Rebuild sqlite3 natively for the container
        echo '==> [Inside Docker] Building native sqlite3 for coverage'
        rm -f packages/sqlite-wasm-rs/sqlite3/libsqlite3.a
        gcc -O3 -c packages/sqlite-wasm-rs/sqlite3/sqlite3.c -o packages/sqlite-wasm-rs/sqlite3/sqlite3.o \
            -DSQLITE_OS_OTHER=1 \
            -DSQLITE_THREADSAFE=0 \
            -DSQLITE_USE_URI=1 \
            -DSQLITE_ENABLE_FTS5=1 \
            -DSQLITE_ENABLE_RTREE=1 \
            -DSQLITE_ENABLE_SESSION=1 \
            -DSQLITE_ENABLE_STMTVTAB=1 \
            -DSQLITE_ENABLE_DBSTAT_VTAB=1 \
            -DSQLITE_ENABLE_COLUMN_METADATA=1
        ar rcs packages/sqlite-wasm-rs/sqlite3/libsqlite3.a packages/sqlite-wasm-rs/sqlite3/sqlite3.o
        
        sh tool/build.sh
        bash tool/build_wasm.sh
        sh tool/prepare_tests.sh

        echo '==> [Inside Docker] Collecting Core (Rust) Coverage'
        cargo tarpaulin --workspace -o Lcov --engine llvm
        mv lcov.info lcov_core.info

        echo '==> [Inside Docker] Collecting Dart Native Coverage'
        cd packages/isar_plus_test
        flutter pub get
        flutter test --coverage
        cp coverage/lcov.info ../isar_plus/lcov_isar_plus_test.info
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
        # Collect and standardize all .info files
        LCOV_INPUTS=""
        
        # Helper function to normalize paths in .info files
        normalize_lcov() {
            local file=\$1
            local pkg_prefix=\$2
            [ -f \"\$file\" ] || return
            echo \"Normalizing \$file\"
            
            # 1. First handle absolute prefixes - turn into relative to project root
            sed -i 's|SF:/app/packages/|SF:|g' \"\$file\"
            sed -i 's|SF:packages/|SF:|g' \"\$file\"
            sed -i 's|SF:/app/|SF:|g' \"\$file\"
            
            # 2. Handle relative paths (../) which point to peer packages
            sed -i 's|SF:\.\./|SF:|g' \"\$file\"
            
            # 3. Handle local paths if we know the package context
            if [ -n \"\$pkg_prefix\" ]; then
                # Prepend the package name if it's missing (starts with lib/ or src/ or native/)
                sed -i \"s|^SF:lib/|SF:\$pkg_prefix/lib/|\" \"\$file\"
                sed -i \"s|^SF:src/|SF:\$pkg_prefix/src/|\" \"\$file\"
                sed -i \"s|^SF:native/|SF:\$pkg_prefix/src/native/|\" \"\$file\"
                sed -i \"s|^SF:sqlite/|SF:\$pkg_prefix/src/sqlite/|\" \"\$file\"
                sed -i \"s|^SF:core/|SF:\$pkg_prefix/src/core/|\" \"\$file\"
            fi
            
            # 4. Specific fix for isar_core if not caught by pkg_prefix
            if [[ \"\$file\" == *\"lcov_core.info\" ]]; then
                sed -i 's|^SF:src/|SF:isar_core/src/|' \"\$file\"
            fi

            # Cleanup any potential double slashes or redundant prefixes
            sed -i 's|SF:packages/|SF:|g' \"\$file\"
        }

        normalize_lcov lcov_core.info \"isar_core\"
        [ -f lcov_core.info ] && grep -q \"SF:\" lcov_core.info && LCOV_INPUTS=\"\$LCOV_INPUTS -a lcov_core.info\"

        normalize_lcov packages/isar_plus/lcov_isar_plus_test.info \"isar_plus_test\"
        [ -f packages/isar_plus/lcov_isar_plus_test.info ] && grep -q \"SF:\" packages/isar_plus/lcov_isar_plus_test.info && LCOV_INPUTS=\"\$LCOV_INPUTS -a packages/isar_plus/lcov_isar_plus_test.info\"

        normalize_lcov packages/isar_plus/lcov_isar_plus_test_web.info \"isar_plus_test\"
        [ -f packages/isar_plus/lcov_isar_plus_test_web.info ] && grep -q \"SF:\" packages/isar_plus/lcov_isar_plus_test_web.info && LCOV_INPUTS=\"\$LCOV_INPUTS -a packages/isar_plus/lcov_isar_plus_test_web.info\"

        if [ -n \"\$LCOV_INPUTS\" ]; then
            echo \"Merging reports with inputs: \$LCOV_INPUTS\"
            lcov \$LCOV_INPUTS -o combined_lcov.info
            
            echo \"Filtering report...\"
            lcov --remove combined_lcov.info \
                '*/generated/*' \
                '*/test/*' \
                '*/.dart_tool/*' \
                '*/.pub-cache/*' \
                '*/usr/*' \
                -o filtered_lcov.info
            
            echo \"==> [Inside Docker] Generating HTML report\"
            rm -rf \$REPORT_DIR
            mkdir -p \$REPORT_DIR
            
            # Run genhtml from the packages directory so that paths starting with
            # isar_core/, isar_plus/, etc. are found correctly and grouped at the top level.
            cd packages
            genhtml ../filtered_lcov.info -o ../\$REPORT_DIR --ignore-errors source
            cd ..
            
            echo \"==> [Inside Docker] Coverage report generated in \$(pwd)/\$REPORT_DIR\"
            # Fix: also copy the filtered info file to the report dir for easier access
            cp filtered_lcov.info \$REPORT_DIR/lcov.info
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
