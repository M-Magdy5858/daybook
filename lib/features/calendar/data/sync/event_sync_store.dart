import 'package:daybook/core/sync/sync_store.dart';
import 'package:daybook/features/calendar/data/datasources/event_local_data_source.dart';
import 'package:daybook/features/calendar/data/models/event_model.dart';

/// Lets the sync engine read and write events.
class EventSyncStore implements SyncStore {
  EventSyncStore(this._local);
  final EventLocalDataSource _local;

  @override
  String get entityType => 'event';

  @override
  String get path => '/events';

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
    [for (final json in items) EventModel.fromJson(json).toEntity()],
  );
}
