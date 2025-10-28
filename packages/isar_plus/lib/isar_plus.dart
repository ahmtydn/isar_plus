/// Fast, easy to use, and fully async NoSQL database for Flutter and Dart.
///
/// Isar Plus is a high-performance embedded database that offers rich
/// features like transactions, queries, watchers, and synchronous/asynchronous
/// operations out of the box.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

import 'package:isar_plus/src/isar_connect_api.dart';
import 'package:isar_plus/src/native/native.dart'
    if (dart.library.js_interop) 'src/web/web.dart';
import 'package:logger/web.dart';
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

part 'src/annotations/collection.dart';
part 'src/annotations/embedded.dart';
part 'src/annotations/enum_value.dart';
part 'src/annotations/id.dart';
part 'src/annotations/ignore.dart';
part 'src/annotations/index.dart';
part 'src/annotations/name.dart';
part 'src/annotations/type.dart';
part 'src/annotations/utc.dart';
part 'src/compact_condition.dart';
part 'src/impl/filter_builder.dart';
part 'src/impl/isar_collection_impl.dart';
part 'src/impl/isar_impl.dart';
part 'src/impl/isar_query_impl.dart';
part 'src/impl/native_error.dart';
part 'src/isar.dart';
part 'src/isar_collection.dart';
part 'src/isar_connect.dart';
part 'src/isar_core.dart';
part 'src/isar_error.dart';
part 'src/isar_generated_schema.dart';
part 'src/isar_query.dart';
part 'src/isar_schema.dart';
part 'src/query_builder.dart';
part 'src/query_components.dart';
part 'src/query_extensions.dart';
part 'src/watcher_details.dart';

/// @nodoc
@protected
/// ignored to avoid "unused import" warnings
// ignore: specify_nonobvious_property_types
const isarProtected = protected;

/// @nodoc
@protected
const String Function(
  Object? object, {
  Object? Function(Object? nonEncodable)? toEncodable,
})
isarJsonEncode = jsonEncode;

/// @nodoc
@protected
const Object? Function(
  String source, {
  Object? Function(Object? key, Object? value)? reviver,
})
isarJsonDecode = jsonDecode;
