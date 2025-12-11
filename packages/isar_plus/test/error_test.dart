import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:isar_plus/src/generator/isar_plus_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Error case', () {
    for (final file in Directory('test/errors').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      test(file.path, () async {
        final content = await file.readAsLines();

        final errorMessage = content.first.split('//').last.trim();

        final readerWriter = TestReaderWriter(rootPackage: 'a');
        await readerWriter.testing.loadIsolateSources();

        final result = await testBuilder(
          getIsarGenerator(BuilderOptions.empty),
          {'a|${file.path}': content.join('\n')},
          readerWriter: readerWriter,
        );

        final errors = result.errors.join('\n');
        expect(errors.toLowerCase(), contains(errorMessage.toLowerCase()));
      });
    }
  });
}
