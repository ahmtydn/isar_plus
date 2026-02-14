import 'package:isar_plus/isar_plus.dart';
import 'package:isar_plus_test/isar_plus_test.dart';
import 'package:test/test.dart';

part 'watcher_detailed_test.g.dart';

@collection
class WatcherModel implements DocumentSerializable {
  WatcherModel(this.id, this.name);

  factory WatcherModel.fromJson(Map<String, dynamic> json) {
    return WatcherModel(
      json['id'] as int,
      json['name'] as String,
    );
  }

  final int id;
  final String name;

  @override
  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatcherModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'WatcherModel(id: $id, name: $name)';
}

void main() {
  group('Watcher Detailed', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([WatcherModelSchema]);
    });

    isarTest('Receive insert event', web: false, () async {
      final listener = Listener<ChangeDetail<WatcherModel>>(
        isar.watcherModels.watchDetailed(documentParser: WatcherModel.fromJson),
      );

      final model = WatcherModel(1, 'Test');
      isar.write((isar) => isar.watcherModels.put(model));

      final event = await listener.next;
      expect(event.changeType, ChangeType.insert);
      expect(event.objectId, 1);
      expect(event.fullDocument, model);
      expect(event.fieldChanges, isNotEmpty);

      await listener.done();
    });

    isarTest('Receive update event', web: false, () async {
      final model = WatcherModel(1, 'Old');
      isar.write((isar) => isar.watcherModels.put(model));

      final listener = Listener<ChangeDetail<WatcherModel>>(
        isar.watcherModels.watchDetailed(documentParser: WatcherModel.fromJson),
      );

      final updated = WatcherModel(1, 'New');
      isar.write((isar) => isar.watcherModels.put(updated));

      final event = await listener.next;
      expect(event.changeType, ChangeType.update);
      expect(event.objectId, 1);
      expect(event.fullDocument, updated);
      expect(event.wasFieldModified('name'), isTrue);
      expect(event.getFieldChange('name')?.oldValue, 'Old');
      expect(event.getFieldChange('name')?.newValue, 'New');

      await listener.done();
    });

    isarTest('Receive delete event', web: false, () async {
      final model = WatcherModel(1, 'Test');
      isar.write((isar) => isar.watcherModels.put(model));

      final listener = Listener<ChangeDetail<WatcherModel>>(
        isar.watcherModels.watchDetailed(documentParser: WatcherModel.fromJson),
      );

      isar.write((isar) => isar.watcherModels.delete(1));

      final event = await listener.next;
      expect(event.changeType, ChangeType.delete);
      expect(event.objectId, 1);

      await listener.done();
    });
  });
}
