#!/bin/sh

cargo install cbindgen

cbindgen --config tool/cbindgen.toml --crate isar --output packages/isar_plus/isar-dart.h

cd packages/isar_plus

dart pub get
dart run ffigen --config ../../tool/ffigen.yaml
rm isar-dart.h

dart format --fix lib/src/native/bindings.dart
