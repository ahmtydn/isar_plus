---
title: Migrar do Isar v3
---

# Migrando do Isar v3 para o Isar Plus v4

Atualizar os pacotes legados `isar` 3.x para `isar_plus` (v4) é uma **mudança incompatível de formato de arquivo**. O núcleo da v4 grava metadados diferentes e não consegue abrir um banco criado com a v3, resultando em erros como:

```
VersionError: The database version is not compatible with this version of Isar.
```

A correção é exportar os dados existentes com o runtime antigo e importá-los em um banco novo do Isar Plus. Os passos abaixo detalham o processo.

## Visão geral da migração

1. Publique (ou mantenha) uma build que ainda dependa de `isar:^3.1.0+1` para conseguir ler os arquivos legados.
2. Adicione `isar_plus` e `isar_plus_flutter_libs` ao lado dos pacotes antigos enquanto migra.
3. Rode novamente o gerador para que os esquemas sejam compilados contra as APIs da v4.
4. Copie todos os registros da instância v3 para uma nova instância do Isar Plus.
5. Apague os arquivos legados e remova as dependências antigas assim que a cópia terminar.

Se você **não** precisa dos dados antigos, basta excluir o diretório da v3 e começar com um banco limpo. O restante deste guia mostra como preservar os registros.

## Atualize as dependências lado a lado

Mantenha o runtime legado até o fim da cópia e só então adicione o novo:

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

Os dois pacotes expõem os mesmos símbolos do Dart, então importe-os com aliases durante a migração:

```dart
import 'package:isar/isar.dart' as legacy;
import 'package:isar_plus/isar_plus.dart' as plus;
```

## Gere novamente os esquemas para a v4

O Isar Plus inclui o gerador dentro do pacote principal. Execute o builder para emitir os novos helpers e adaptadores:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Pausa para corrigir qualquer erro de compilação (por exemplo, campos `Id?` devem virar `int id` ou usar `Isar.autoIncrement`). O [guia de migração da API](https://github.com/ahmtydn/isar_plus/blob/main/packages/isar_plus/README.md#api-migration-guide) resume as mudanças principais:

- `writeTxn()` -> `writeAsync()` e `writeTxnSync()` -> `write()`
- `txn()` -> `readAsync()` e `txnSync()` -> `read()`
- IDs devem se chamar `id` ou receber `@id`; o auto-incremento agora usa `Isar.autoIncrement`
- `@enumerated` virou `@enumValue`
- Objetos embutidos substituem a maior parte dos links legados

## Copie os dados

Crie uma rotina de migração pontual (por exemplo em `main()` antes de iniciar o app, ou em um `bin/migrate.dart`). O padrão é:

1. Abra o banco legado com o runtime da v3.
2. Abra uma nova instância v4 em outro diretório ou com outro nome.
3. Percorra cada coleção em páginas, adapte ao novo esquema e faça `put` no novo banco.
4. Marque a migração como concluída (SharedPreferences, arquivo local ou feature flag) para evitar execuções duplicadas.

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
    engine: plus.IsarEngine.sqlite, // ou IsarEngine.isar para o core nativo
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

> Dica: mantenha funções de mapeamento (como `_mapStatus`) ao lado da rotina para tratar renomeações de enums, remoção de campos ou limpeza de dados em um só lugar.

Se a coleção for enorme, execute o loop em um isolate ou serviço em segundo plano para não travar a UI. O mesmo vale para objetos embutidos e links: carregue com a API legada e persista com o novo esquema.

## Garanta que só rode uma vez em produção

Enquanto os dois runtimes estiverem no app, todo cold start pode tentar migrar de novo se você não controlar com uma flag. Persista um estado para rodar a cópia apenas uma vez por instalação:

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

Em vez de um booleano, você pode salvar um número de versão (por exemplo `3` para legacy e `4` para Isar Plus) se prever futuras migrações. Em desktop ou servidor, um arquivo `.migrated` ao lado do diretório do banco também funciona.

## Limpeza

Depois de copiar todas as coleções:

1. Salve uma flag (por exemplo `prefs.setBool('migratedToIsarPlus', true)`) para impedir novas execuções.
2. Apague os arquivos legados manualmente ou com `plus.Isar.deleteDatabase(name: 'legacy', directory: directoryPath, engine: plus.IsarEngine.isar)`.
3. Remova `isar` e `isar_flutter_libs` do `pubspec.yaml`.
4. Renomeie o novo banco para o nome/diretório original, se necessário.

Somente depois de ter certeza de que ninguém abre mais o build legado publique uma versão que dependa apenas de `isar_plus`.

## Solução de problemas

- **`VersionError` ainda aparece**: confirme que os arquivos da v3 foram apagados antes de abrir a instância v4. WAL/LCK antigos podem preservar o cabeçalho legado.
- **Chaves primárias duplicadas**: IDs na v4 precisam ser inteiros únicos e não nulos. Use `Isar.autoIncrement` ou gere chaves próprias durante a cópia.
- **Gerador falhou**: execute `dart pub clean` antes de `build_runner` e verifique se não há `part '...g.dart';` faltando.
- **Precisa reverter**: como a migração escreve em um banco separado, você pode descartar os arquivos novos e manter os legados até que a cópia concluída esteja validada.

Seguindo estes passos, os usuários podem sair direto de um build `isar` 3.x para uma versão `isar_plus` sem perda de dados.
