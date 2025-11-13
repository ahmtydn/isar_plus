---
title: Migrar desde Isar v3
---

# Migración de Isar v3 a Isar Plus v4

Actualizar los paquetes heredados `isar` 3.x a `isar_plus` (v4) es un **cambio incompatible en el formato de archivos**. El núcleo de v4 escribe metadatos distintos y no puede abrir una base escrita por v3, por lo que verás errores como:

```
VersionError: The database version is not compatible with this version of Isar.
```

La solución es exportar tus datos con el runtime antiguo e importarlos en una base nueva de Isar Plus. Los pasos siguientes describen el proceso.

## Resumen de la migración

1. Publica (o conserva) una build que dependa de `isar:^3.1.0+1` para poder leer los archivos heredados.
2. Agrega `isar_plus` e `isar_plus_flutter_libs` junto a los paquetes antiguos mientras migras.
3. Ejecuta de nuevo el generador para que tus esquemas compilen contra las API de v4.
4. Copia cada registro de la instancia v3 a una instancia nueva de Isar Plus.
5. Elimina los archivos heredados y quita las dependencias antiguas cuando la copia termine.

Si **no** necesitas los datos viejos, basta con borrar el directorio de v3 y comenzar con una base vacía. El resto de esta guía se enfoca en preservar los registros existentes.

## Actualiza las dependencias en paralelo

Mantén el runtime legado hasta que la copia finalice y luego añade el nuevo:

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

Ambos paquetes exponen los mismos símbolos de Dart, así que impórtalos con alias durante la migración:

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## Regenera tus esquemas para v4

Isar Plus incluye su generador dentro del paquete principal. Vuelve a ejecutar el builder para que emita los nuevos helpers y adaptadores:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Haz una pausa y corrige cualquier error de compilación (por ejemplo, los campos `Id?` deben volverse `int id` o usar `Isar.autoIncrement`). La [guía de migración de la API](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide) resume los cambios clave:

- `writeTxn()` -> `writeAsync()` y `writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()` y `txnSync()` -> `read()`
- Los ID deben llamarse `id` o llevar `@id`; el auto-incremento ahora usa `Isar.autoIncrement`
- `@enumerated` pasó a `@enumValue`
- Los objetos embebidos sustituyen la mayoría de los enlaces heredados

## Copia los datos reales

Crea una rutina de migración puntual (por ejemplo en `main()` antes de iniciar tu app o en un `bin/migrate.dart`). El patrón es:

1. Abre el almacén heredado con el runtime de v3.
2. Abre una instancia v4 nueva en otro directorio o con otro nombre.
3. Recorre cada colección por páginas, ajusta los modelos al nuevo esquema y haz `put` en la base nueva.
4. Marca la migración como finalizada (SharedPreferences, archivo local o feature flag) para no ejecutarla dos veces.

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
    engine: plus.IsarEngine.sqlite, // o IsarEngine.isar para el core nativo
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

> Consejo: Mantén las funciones de mapeo (como `_mapStatus`) junto a la rutina para manejar renombrados de enums, campos removidos o limpieza de datos en un solo lugar.

Si tienes colecciones enormes, ejecuta el bucle en un isolate o servicio en segundo plano para no bloquear la UI. El mismo patrón aplica para objetos embebidos y enlaces: cárgalos con la API heredada y persístelos con el nuevo esquema.

## Asegura que solo se ejecute una vez en producción

Cuando distribuyes ambos runtimes, cada inicio en frío podría intentar migrar de nuevo a menos que lo controles con una bandera. Persiste una versión o estado para que la copia corra solo una vez por instalación:

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

En lugar de un booleano puedes guardar una versión numérica del esquema (por ejemplo `3` para legacy y `4` para Isar Plus) si esperas migraciones futuras. En escritorio o servidor también puedes escribir un archivo `.migrated` junto al directorio de la base.

## Limpieza

Después de copiar todas las colecciones:

1. Guarda una bandera (por ejemplo `prefs.setBool('migratedToIsarPlus', true)`) para que la migración no vuelva a ejecutarse.
2. Borra los archivos heredados (manualmente o con `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)`).
3. Quita las dependencias `isar` e `isar_flutter_libs` de `pubspec.yaml`.
4. Renombra la base nueva a tu nombre/directorio original si lo necesitas.

Solo cuando estés seguro de que ningún usuario abre la build heredada deberías publicar una actualización que dependa únicamente de `isar_plus`.

## Resolución de problemas

- **Sigue apareciendo `VersionError`**: Asegúrate de borrar los archivos de v3 antes de abrir la instancia v4. Los archivos WAL/LCK antiguos pueden mantener el encabezado heredado.
- **Claves primarias duplicadas**: Los ID en v4 deben ser enteros únicos y no nulos. Usa `Isar.autoIncrement` o genera tus propios identificadores al copiar.
- **El generador falla**: Ejecuta `dart pub clean` antes de `build_runner` y confirma que no falten directivas `part '...g.dart';`.
- **Necesitas revertir**: Como la migración escribe en una base separada, puedes descartar los archivos nuevos y conservar los heredados hasta que la copia termine.

Con estos pasos listos, tus usuarios pueden actualizar directamente de un build con `isar` 3.x a una versión con `isar_plus` sin perder datos.
