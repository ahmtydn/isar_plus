rustup target add wasm32-unknown-unknown
cargo build --target wasm32-unknown-unknown --features sqlite --no-default-features -p isar_plus --release
mv "target/wasm32-unknown-unknown/release/isar.wasm" "isar.wasm"