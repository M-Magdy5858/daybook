/// What the [SyncEngine] needs from one kind of item's local storage.
/// Items travel as JSON maps with `id`, `updatedAt` (ISO-8601) and `version`.
abstract interface class SyncStore {
  /// The outbox `entityType`, e.g. `'task'`.
  String get entityType;

  /// The REST collection, e.g. `'/tasks'`.
  String get path;

  /// `updatedAt` and `version` of every local item, keyed by id.
  Future<Map<String, ({DateTime updatedAt, int version})>> syncInfo();

  Future<int?> versionOf(String id);

  /// Records the server's version after it accepted a change, without
  /// touching any newer local edits.
  Future<void> setVersion(String id, int version);

  /// Saves server copies locally.
  Future<void> upsertJson(List<Map<String, dynamic>> items);
}
