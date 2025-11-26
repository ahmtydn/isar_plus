import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isar_plus/isar_plus.dart';
import 'package:path_provider/path_provider.dart';

part 'main.g.dart';

/// Metadata for a counter step, stored as an embedded object.
@embedded
class StepMetadata {
  const StepMetadata({required this.recordedAt, this.note = ''});

  final DateTime recordedAt;
  final String note;
}

/// Represents a single counter increment with metadata.
@collection
class Count {
  Count({required this.id, required this.step, required this.metadata});

  final int id;
  final int step;
  final StepMetadata metadata;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Isar.initialize();
  }

  runApp(const CounterApp());
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isar Counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
      ),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  Isar? _isar;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      final directory = kIsWeb
          ? null
          : await getApplicationDocumentsDirectory();
      final isar = Isar.open(
        schemas: [CountSchema],
        directory: directory?.path ?? 'isar_data',
        engine: kIsWeb ? IsarEngine.sqlite : IsarEngine.isar,
      );

      if (mounted) {
        setState(() {
          _isar = isar;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize database: $e';
        });
      }
    }
  }

  int _getCurrentCount() {
    final isar = _isar;
    if (isar == null) return 0;
    return isar.counts.where().stepProperty().sum();
  }

  Count? _getLatestCount() {
    final isar = _isar;
    if (isar == null) return null;
    return isar.counts.where().sortByIdDesc().findFirst();
  }

  Future<void> _incrementCounter() async {
    final isar = _isar;
    if (isar == null) return;

    try {
      isar.write((isarInstance) {
        final nextId = isarInstance.counts.where().idProperty().max() ?? 0;
        isarInstance.counts.put(
          Count(
            id: nextId + 1,
            step: 1,
            metadata: StepMetadata(
              recordedAt: DateTime.now(),
              note: 'Manual increment',
            ),
          ),
        );
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving count: $e')));
      }
    }
  }

  @override
  void dispose() {
    _isar?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Isar Counter')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_isar == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Isar Counter')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final count = _getCurrentCount();
    final latest = _getLatestCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Isar Counter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'You have pushed the button this many times:',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '$count',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (latest != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Last Recorded',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDateTime(latest.metadata.recordedAt),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}
