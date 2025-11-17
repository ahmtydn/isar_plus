---
title: Isar v3 からの移行
---

# Isar v3 から Isar Plus v4 へ移行する

レガシーな `isar` 3.x パッケージを `isar_plus` (v4) にアップグレードすることは、**互換性のないファイルフォーマットの変更**です。v4 コアはまったく別のメタデータを書き込むため、v3 が作成したデータベースを開けず、次のようなエラーが発生します。

```
VersionError: The database version is not compatible with this version of Isar.
```

解決策は、旧ランタイムで既存データをエクスポートし、クリーンな Isar Plus データベースにインポートし直すことです。以下の手順に従ってください。

## 移行の流れ

1. レガシーファイルを読み取れるよう、`isar:^3.1.0+1` に依存したビルドを出荷 (または維持) します。
2. 移行中は `isar_plus` と `isar_plus_flutter_libs` を既存パッケージの隣に追加します。
3. コードジェネレーターを再実行し、スキーマを v4 API に再コンパイルします。
4. v3 インスタンスから新しい Isar Plus インスタンスへ、全レコードをコピーします。
5. コピーが成功したらレガシーファイルを削除し、古い依存関係を取り除きます。

古いデータが**不要**であれば、v3 ディレクトリを削除して空のデータベースで再スタートしてもかまいません。このガイドは既存レコードを保持するケースに集中しています。

## 依存関係を並行して更新する

コピーが終わるまで旧ランタイムを残し、その後で新ランタイムを追加します。

```yaml
dependencies:

  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
  isar_generator: ^3.1.0+1
  isar_plus: ^1.1.5
  isar_plus_flutter_libs: ^1.1.5

dev_dependencies:
  build_runner: ^2.4.10
```

両パッケージは同じ Dart シンボルを公開しているため、移行期間は必ずエイリアスを付けてインポートします。

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## v4 用にスキーマを再生成する

Isar Plus はジェネレーターをメインパッケージに同梱しています。ビルダーを再実行し、新しいヘルパーとアダプターを生成しましょう。

```bash
dart run build_runner build --delete-conflicting-outputs
```

ここで一旦止まり、コンパイルエラーを解消します (例: `Id?` は `int id` か `Isar.autoIncrement` に変更する)。[API 移行ガイド](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide)には主な変更点がまとまっています。

- `writeTxn()` -> `writeAsync()`、`writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()`、`txnSync()` -> `read()`
- ID は `id` という名前か `@id` が必須。自動採番は `Isar.autoIncrement`
- `@enumerated` は `@enumValue` へ名称変更
- 多くのレガシーリンクは埋め込みオブジェクトで置き換え

## 実データをコピーする

単発の移行ルーチンを用意します (例: アプリ起動前の `main()` あるいは `bin/migrate.dart`)。基本パターンは次の通りです。

1. v3 ランタイムでレガシーストアを開く。
2. 異なるディレクトリまたは名前で新しい v4 インスタンスを開く。
3. 各コレクションをページングし、新スキーマにマッピングして新データベースへ `put` する。
4. SharedPreferences やローカルファイル、フラグで完了を記録し、二重実行を防ぐ。

```dart
Future<void> migrateLegacyDb(String directoryPath) async {
  final legacyDb = await legacy.Isar.open(
    [LegacyUserSchema, LegacyTodoSchema],
    directory: directoryPath,
    inspector: false,
    name: 'legacy',
  );

  final plusDb = await plus.Isar.open(
    [UserSchema, TodoSchema],
    directory: directoryPath,
    name: 'app_v4',
    engine: plus.IsarEngine.sqlite, // ネイティブコアなら IsarEngine.isar
    inspector: false,
  );

  await _copyUsers(legacyDb, plusDb);
  await _copyTodos(legacyDb, plusDb);

  await legacyDb.close();
  await plusDb.close();
}

Future<void> _copyUsers(legacy.Isar legacyDb, plus.Isar plusDb) async {
  const pageSize = 200;
  final total = await legacyDb.legacyUsers.count();

  for (var offset = 0; offset < total; offset += pageSize) {
    final batch = await legacyDb.legacyUsers.where().offset(offset).limit(pageSize).findAll();
    await plusDb.writeAsync((isar) async {
      await isar.users.putAll(
        batch.map((user) => User(
              id: user.id ?? plus.Isar.autoIncrement,
              email: user.email,
              status: _mapStatus(user.status),
            )),
      );
    });
  }
}
```

> ヒント: `_mapStatus` のようなマッピング関数は移行ルーチンの近くに置き、列挙型の名称変更・フィールド削除・データ修正を一括で扱えるようにします。

巨大なコレクションを扱う場合は、ループを isolate やバックグラウンドサービス内で実行し、UI スレッドを塞がないようにします。埋め込みオブジェクトやリンクも同じ手順で移行できます。

## 本番では一度だけ実行させる

両方のランタイムを同梱している間は、毎回のコールドスタートで再移行が走り得ます。必ずフラグを永続化し、インストールごとに一度だけコピーされるようにしましょう。

```dart
class MigrationTracker {
  static const key = 'isarPlusMigration';

  static Future<bool> needsMigration() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.getBool(key).toString().contains('true');
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}

Future<void> bootstrapIsar(String dir) async {
  if (await MigrationTracker.needsMigration()) {
    await migrateLegacyDb(dir);
    await MigrationTracker.markDone();
  }

  final isar = await plus.Isar.open(
    [UserSchema, TodoSchema],
    directory: dir,
  );

  runApp(MyApp(isar: isar));
}
```

将来的な移行を想定するなら、ブール値ではなく数値のスキーマバージョン (`3` はレガシー、`4` は Isar Plus) を保存しても構いません。デスクトップやサーバーでは、データベースディレクトリの隣に `.migrated` ファイルを置く方法もあります。

## 後片付け

全コレクションのコピー後は次を実施します。

1. `prefs.setBool('migratedToIsarPlus', true)` などのフラグを保存し、再実行を防ぐ。
2. レガシーファイルを削除する (手動または `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)` を使用)。
3. `pubspec.yaml` から `isar` と `isar_flutter_libs` を削除する。
4. 必要であれば新しいデータベース名/ディレクトリを元の名称に戻す。

ユーザーがレガシービルドを開かないと確信できたタイミングで、`isar_plus` のみを依存に持つアップデートを公開してください。

## トラブルシューティング

- **`VersionError` が消えない**: v4 インスタンスを開く前に v3 のファイルを削除してください。古い WAL/LCK ファイルがヘッダーを保持していることがあります。
- **主キーが重複する**: v4 では ID が一意で非 null の整数である必要があります。コピー時に `Isar.autoIncrement` か独自のキー生成を使用してください。
- **ジェネレーターが失敗する**: `dart pub clean` を実行してから `build_runner` を走らせ、`part '...g.dart';` の不足がないか確認します。
- **ロールバックしたい**: 別ディレクトリへ書き込む構成なので、新しいファイルを破棄してレガシーデータを維持できます。

これらの手順を整えれば、ユーザーは `isar` 3.x ビルドから `isar_plus` リリースへ安全にアップグレードできます。
