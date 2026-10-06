import 'package:daybook/core/sync/sync_store.dart';
import 'package:daybook/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:daybook/features/tasks/data/models/task_model.dart';

/// Lets the sync engine read and write tasks.
class TaskSyncStore implements SyncStore {
  TaskSyncStore(this._local);
  final TaskLocalDataSource _local;

  @override
  String get entityType => 'task';

  @override
  String get path => '/tasks';

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
    [for (final json in items) TaskModel.fromJson(json).toEntity()],
  );
}
