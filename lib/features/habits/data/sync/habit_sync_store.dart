import 'package:daybook/core/sync/sync_store.dart';
import 'package:daybook/features/habits/data/datasources/habit_local_data_source.dart';
import 'package:daybook/features/habits/data/models/habit_model.dart';

/// Lets the sync engine read and write habits.
class HabitSyncStore implements SyncStore {
  HabitSyncStore(this._local);
  final HabitLocalDataSource _local;

  @override
  String get entityType => 'habit';

  @override
  String get path => '/habits';

  @override
  Future<Map<String, ({DateTime updatedAt, int version})>> syncInfo() =>
      _local.syncInfo();

  @override
  Future<int?> versionOf(String id) async =>
      (await _local.getById(id))?.version;

  @override
  Future<void> setVersion(String id, int version) =>
      _local.setVersion(id, version);

  @override
  Future<void> upsertJson(List<Map<String, dynamic>> items) => _local.upsertAll(
    [for (final json in items) HabitModel.fromJson(json).toEntity()],
  );
}
