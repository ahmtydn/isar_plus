import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isar_plus/isar_plus.dart';

part 'main.g.dart';

@embedded
class StepMetadata {
  const StepMetadata({
    required this.recordedAt,
    this.note = '',
  });

  final DateTime recordedAt;

  final String note;
}

@collection
class Count {
  final int id;

  final int step;

  final StepMetadata metadata;

  Count(this.id, this.step, this.metadata);
}

void main() async {
  if (kIsWeb) {
    await Isar.initialize();
  }
  runApp(const CounterApp());
}

class CounterApp extends StatefulWidget {
  const CounterApp({super.key});

  @override
  State<CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  late Isar _isar;

  @override
  void initState() {
    // Open Isar instance
    _isar = Isar.open(
      schemas: [CountSchema],
      directory: "isar_data",
      engine: IsarEngine.sqlite,
    );
    super.initState();
  }

  void _incrementCounter() {
    // Persist counter value to database
    _isar.write((isar) async {
      isar.counts.put(
        Count(
          isar.counts.autoIncrement(),
          1,
          StepMetadata(
            recordedAt: DateTime.now(),
            note: 'Manual increment',
          ),
        ),
      );
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This is just for demo purposes. You shouldn't perform database queries
    // in the build method.
    final count = _isar.counts.where().stepProperty().sum();
    final latest = _isar.counts.where().sortByIdDesc().findFirst();
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Isar Counter',
      theme: theme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Isar Counter')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('You have pushed the button this many times:'),
              Text('$count', style: theme.textTheme.headlineMedium),
              if (latest != null)
                Text(
                  'Last step recorded at ${latest.metadata.recordedAt}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
