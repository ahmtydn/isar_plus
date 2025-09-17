import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:isar_plus_generator/isar_generator.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('Error case', () {
    for (final file in Directory('test/errors').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      test(file.path, () async {
        final content = await file.readAsLines();

        final errorMessage = content.first.split('//').last.trim();

        var error = '';
        try {
          final readerWriter = TestReaderWriter(
            rootPackage: 'isar_plus_generator',
          );
          await readerWriter.testing.loadIsolateSources();

          await testBuilder(
            getIsarGenerator(BuilderOptions.empty),
            {'a|${file.path}': content.join('\n')},
            readerWriter: readerWriter,
            onLog: (record) {
              if (record.level >= Level.SEVERE) {
                error = record.message;
              }
            },
          );
        } on Exception catch (e) {
          error = e.toString();
        }

        expect(error.toLowerCase(), contains(errorMessage.toLowerCase()));
      });
    }
  });
}
