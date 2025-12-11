import 'dart:io';

import 'package:path/path.dart' as p;

void main() {
  _recreateIntegrationTestDirectory();
  final testFiles = _discoverTestFiles();
  final testRunner = _generateTestRunner(testFiles);
  _writeTestRunner(testRunner);
}

void _recreateIntegrationTestDirectory() {
  final integrationTestDir = Directory('integration_test/test');

  if (integrationTestDir.existsSync()) {
    integrationTestDir.deleteSync(recursive: true);
  }

  _copyDirectory(Directory('test'), integrationTestDir);
}

List<File> _discoverTestFiles() {
  return Directory('test')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('_test.dart'))
      .toList();
}

String _generateTestRunner(List<File> testFiles) {
  final imports = _generateImports(testFiles);
  final calls = _generateTestCalls(testFiles);

  return '''
import 'package:isar_plus_test/isar_plus_test.dart';

$imports

void main() {
  const stress = bool.fromEnvironment('STRESS');
  
$calls
}
''';
}

String _generateImports(List<File> testFiles) {
  return testFiles
      .map((file) {
        final dartPath = file.path.replaceAll(p.separator, '/');
        final alias = _generateImportAlias(file.path);
        return "import '$dartPath' as $alias;";
      })
      .join('\n');
}

String _generateTestCalls(List<File> testFiles) {
  return testFiles
      .map((file) {
        final alias = _generateImportAlias(file.path);
        final call = '$alias.main();';

        return _wrapCallWithConditionals(file, call);
      })
      .map((call) => '  $call')
      .join('\n');
}

String _wrapCallWithConditionals(File file, String call) {
  final content = file.readAsStringSync();
  final isStressTest = file.path.contains('stress');
  final isVmOnly = content.startsWith("@TestOn('vm')");

  if (isStressTest && isVmOnly) {
    return 'if (stress && !kIsWeb) $call';
  } else if (isStressTest) {
    return 'if (stress) $call';
  } else if (isVmOnly) {
    return 'if (!kIsWeb) $call';
  } else {
    return call;
  }
}

String _generateImportAlias(String filePath) {
  return filePath
      .split('.')[0]
      .replaceAll(p.separator, '_')
      .replaceAll(RegExp(r'[^\w]'), '_');
}

void _writeTestRunner(String content) {
  final outputFile = File('integration_test/all_tests.dart');
  outputFile.writeAsStringSync(content);
  stdout.writeln('✓ Generated ${outputFile.path}');
}

void _copyDirectory(Directory source, Directory destination) {
  destination.createSync(recursive: true);

  for (final entity in source.listSync()) {
    final destinationPath = p.join(destination.path, p.basename(entity.path));

    if (entity is Directory) {
      _copyDirectory(entity, Directory(destinationPath));
    } else if (entity is File) {
      entity.copySync(destinationPath);
    }
  }
}
