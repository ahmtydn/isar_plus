---
title: Isar v3 마이그레이션
---

# Isar v3에서 Isar Plus v4로 마이그레이션

레거시 `isar` 3.x 패키지를 `isar_plus`(v4)로 올리는 작업은 **파일 포맷이 완전히 바뀌는 호환 불가 변경**입니다. v4 코어는 서로 다른 메타데이터를 기록하므로 v3가 만든 데이터베이스를 열 수 없고, 다음과 같은 오류가 발생합니다.

```
VersionError: The database version is not compatible with this version of Isar.
```

해결 방법은 기존 데이터를 레거시 런타임으로 내보낸 뒤, 새 Isar Plus 데이터베이스로 다시 가져오는 것입니다. 아래 단계에 따라 진행하세요.

## 마이그레이션 개요

1. 레거시 파일을 읽을 수 있도록 `isar:^3.1.0+1`에 의존하는 빌드를 유지하거나 배포합니다.
2. 마이그레이션 동안 `isar_plus`와 `isar_plus_flutter_libs`를 기존 패키지 옆에 추가합니다.
3. 코드 생성기를 다시 실행해 스키마가 v4 API에 맞춰 컴파일되도록 합니다.
4. v3 인스턴스의 모든 레코드를 새 Isar Plus 인스턴스로 복사합니다.
5. 복사가 완료되면 레거시 파일을 삭제하고 오래된 의존성을 제거합니다.

이전 데이터가 **필요 없다면**, v3 디렉터리를 삭제하고 새 데이터베이스로 시작해도 됩니다. 이후 내용은 데이터를 보존하는 경우를 다룹니다.

## 의존성을 나란히 업데이트하기

복사가 끝날 때까지 기존 런타임을 유지한 후 새 런타임을 추가하세요.

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

두 패키지는 동일한 Dart 심볼을 노출하므로, 마이그레이션 중에는 항상 별칭으로 import 하세요.

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## v4용 스키마 다시 생성하기

Isar Plus는 메인 패키지 내부에 생성기를 포함합니다. 빌더를 다시 실행해 새로운 헬퍼와 어댑터를 생성하세요.

```bash
dart run build_runner build --delete-conflicting-outputs
```

여기서 잠시 멈추고 컴파일 오류를 해결합니다(예: nullable `Id?` 필드는 `int id` 또는 `Isar.autoIncrement`로 바꿔야 함). [API 마이그레이션 가이드](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide)에 핵심 변경 사항이 정리되어 있습니다.

- `writeTxn()` -> `writeAsync()`, `writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()`, `txnSync()` -> `read()`
- ID는 `id`라는 이름을 사용하거나 `@id`로 표시해야 하며, 자동 증가에는 `Isar.autoIncrement` 사용
- `@enumerated` 가 `@enumValue` 로 변경
- 대부분의 레거시 링크는 임베디드 객체로 대체

## 실제 데이터 복사

단발성 마이그레이션 루틴을 작성하세요(예: 앱 초기화 전에 `main()`에서 실행하거나 별도 `bin/migrate.dart` 작성). 패턴은 다음과 같습니다.

1. v3 런타임으로 레거시 저장소를 연다.
2. 다른 디렉터리나 이름으로 새로운 v4 인스턴스를 연다.
3. 각 컬렉션을 페이지 단위로 읽고 새 스키마에 매핑한 뒤 새 DB에 `put` 한다.
4. SharedPreferences, 로컬 파일 또는 기능 플래그로 마이그레이션 완료 여부를 저장해 재실행을 막는다.

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
    engine: plus.IsarEngine.sqlite, // 네이티브 코어를 쓰려면 IsarEngine.isar
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

> 팁: `_mapStatus` 같은 매핑 함수는 마이그레이션 루틴 옆에 두면 enum 이름 변경, 필드 제거, 데이터 정리를 한곳에서 처리할 수 있습니다.

컬렉션이 매우 크다면 루프를 isolate나 백그라운드 서비스에서 실행해 UI가 멈추지 않도록 하세요. 임베디드 객체와 링크도 동일한 방식으로 옮길 수 있습니다.

## 프로덕션에서 한 번만 실행되도록 하기

두 런타임을 함께 배포하면 매번 콜드 스타트 시 마이그레이션이 다시 실행될 수 있습니다. 상태 플래그를 저장해 설치당 한 번만 복사가 돌도록 하세요.

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

향후 추가 마이그레이션을 예상한다면 불리언 대신 숫자 스키마 버전(예: 레거시는 `3`, Isar Plus는 `4`)을 저장해도 좋습니다. 데스크톱/서버 환경에서는 데이터베이스 폴더 옆에 `.migrated` 파일을 만들어도 됩니다.

## 정리하기

모든 컬렉션을 복사한 뒤에는 다음을 수행하세요.

1. `prefs.setBool('migratedToIsarPlus', true)` 같은 플래그를 저장해 재실행을 막습니다.
2. 레거시 파일을 삭제합니다(수동 또는 `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)` 호출).
3. `pubspec.yaml`에서 `isar`와 `isar_flutter_libs` 의존성을 제거합니다.
4. 필요하다면 새 데이터베이스 이름/디렉터리를 원래 이름으로 되돌립니다.

사용자들이 더 이상 레거시 빌드를 열지 않는다고 확신할 때 `isar_plus`만 의존하는 업데이트를 배포하세요.

## 문제 해결

- **`VersionError`가 계속된다**: v4 인스턴스를 열기 전에 v3 파일을 삭제했는지 확인하세요. 오래된 WAL/LCK 파일이 헤더를 유지할 수 있습니다.
- **기본 키 중복**: v4의 ID는 고유한 non-null 정수여야 합니다. `Isar.autoIncrement`를 사용하거나 복사 과정에서 직접 키를 생성하세요.
- **제너레이터 실패**: `dart pub clean` 후 `build_runner`를 실행하고 `part '...g.dart';` 지시문이 누락되지 않았는지 확인합니다.
- **롤백이 필요**: 별도의 데이터베이스에 기록하므로 새 파일을 삭제하고 레거시 데이터를 유지한 채 다시 시도할 수 있습니다.

이 절차를 갖추면 사용자는 `isar` 3.x 빌드에서 `isar_plus` 릴리스로 안전하게 업데이트할 수 있습니다.
