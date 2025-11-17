---
title: 从 Isar v3 迁移
---

# 从 Isar v3 升级到 Isar Plus v4

把旧的 `isar` 3.x 包升级到 `isar_plus` (v4) 属于**破坏性文件格式更新**。v4 核心写入的元数据与 v3 完全不同，因此无法打开旧数据库，会抛出如下错误：

```
VersionError: The database version is not compatible with this version of Isar.
```

解决办法是用旧运行时导出现有数据，再导入到一个全新的 Isar Plus 数据库中。下面的步骤会逐一说明。

## 迁移流程概览

1. 先发布（或保留）一个仍依赖 `isar:^3.1.0+1` 的版本，用它来读取旧文件。
2. 在迁移期间，把 `isar_plus` 与 `isar_plus_flutter_libs` 和旧包并行加入项目。
3. 重新运行代码生成器，让所有 Schema 针对 v4 API 重新编译。
4. 将 v3 实例里的每条记录复制到全新的 Isar Plus 实例中。
5. 复制完成后删除旧文件，并移除旧依赖。

如果你**不需要**旧数据，可以直接删除 v3 目录并重新创建空数据库。本文其余部分专注于保留已有数据。

## 并行更新依赖

在复制完成之前保留旧运行时，之后再引入新的运行时：

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

两个包导出的 Dart 符号相同，因此迁移时务必用别名导入：

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## 为 v4 重新生成 Schema

Isar Plus 自带生成器。重新运行 builder，就能吐出新的 helper 和适配器：

```bash
dart run build_runner build --delete-conflicting-outputs
```

此时暂停并处理所有编译错误（例如 `Id?` 字段需要改成非空 `int id` 或使用 `Isar.autoIncrement`）。[API 迁移指南](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide) 总结了关键改动：

- `writeTxn()` -> `writeAsync()`，`writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()`，`txnSync()` -> `read()`
- ID 必须叫 `id` 或添加 `@id`，自增使用 `Isar.autoIncrement`
- `@enumerated` 改名为 `@enumValue`
- 大部分旧链接由嵌入对象取代

## 复制真实数据

写一个一次性的迁移脚本（比如在 `main()` 初始化应用之前，或单独的 `bin/migrate.dart`）。通用思路：

1. 使用 v3 运行时打开旧库。
2. 在不同目录或不同名称下打开新的 v4 实例。
3. 按页遍历每个集合，映射到新 Schema，并写入新库。
4. 通过 SharedPreferences、本地文件或特性开关记录“已迁移”状态，避免重复执行。

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
    engine: plus.IsarEngine.sqlite, // 原生核心可使用 IsarEngine.isar
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

> 提示：把 `_mapStatus` 这类映射函数和迁移脚本放在一起，方便集中处理枚举改名、字段删除或数据清洗。

如果集合非常大，可以把循环放到 isolate 或后台服务中，以免阻塞 UI。嵌入对象和链接也能用同样方式搬运——用旧 API 读取，用新 Schema 持久化。

## 确保线上只跑一次

当应用同时包含两套运行时时，每次冷启动都有可能再次尝试迁移。记得把状态持久化，让复制过程在每次安装时只运行一次：

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

如果预计未来还会迁移，可以存储一个数值版本（例如 `3` 表示旧库，`4` 表示 Isar Plus）。桌面或服务器环境也可以在数据库目录旁放一个 `.migrated` 文件作为标记。

## 后续清理

所有集合复制完毕后：

1. 写入一个标记（如 `prefs.setBool('migratedToIsarPlus', true)`）防止重复执行。
2. 删除旧文件（手动或调用 `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)`）。
3. 从 `pubspec.yaml` 移除 `isar` 与 `isar_flutter_libs` 依赖。
4. 如有需要，把新数据库的名称/目录改回原来的名字。

只有在确信用户不会再打开旧版本后，才发布只依赖 `isar_plus` 的版本。

## 常见问题

- **仍然出现 `VersionError`**：在打开 v4 实例前请删除所有 v3 文件，旧的 WAL/LCK 文件可能残留旧头部。
- **主键冲突**：v4 要求 ID 是唯一且非空的整数，使用 `Isar.autoIncrement` 或在复制时生成自定义主键。
- **代码生成失败**：先运行 `dart pub clean`，再跑 `build_runner`，并确认 `part '...g.dart';` 没有缺失。
- **需要回滚**：迁移写入的是独立数据库，因此可以直接丢弃新文件，保留旧数据重新尝试。

完成这些步骤后，用户就能直接从 `isar` 3.x 升级到 `isar_plus`，不会丢失数据。
