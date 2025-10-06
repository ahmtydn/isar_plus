import 'package:isar_plus/isar_plus.dart';

part 'asset.g.dart';

@collection
class Asset {
  Asset({
    required this.package,
    required this.version,
    required this.kind,
    required this.content,
  });

  @Id()
  String get id => '$package$version$kind';

  final String package;

  final String version;

  final AssetKind kind;

  final String content;
}

enum AssetKind { readme, changelog }
