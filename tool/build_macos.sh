export MACOSX_DEPLOYMENT_TARGET=10.15

rustup target add aarch64-apple-darwin x86_64-apple-darwin
cargo build --target aarch64-apple-darwin --features sqlcipher --release
cargo build --target x86_64-apple-darwin --features sqlcipher --release

lipo "target/aarch64-apple-darwin/release/libisar.dylib" "target/x86_64-apple-darwin/release/libisar.dylib" -output "libisar_macos.dylib" -create
install_name_tool -id @rpath/libisar.dylib libisar_macos.dylib

# macOS static universal binary for XCFramework (SPM)
lipo "target/aarch64-apple-darwin/release/libisar.a" "target/x86_64-apple-darwin/release/libisar.a" -output "libisar_macos.a" -create
echo "Created libisar_macos.a (static universal binary for SPM)"