import 'dart:convert';

import 'package:daybook/core/storage/app_database.dart';
import 'package:drift/drift.dart';

/// Local changes waiting to reach the server (the `pending_mutations` table).
class Outbox {
  Outbox(this._db);
  final AppDatabase _db;

  /// Call inside the same transaction as the local write, so both are kept or
  /// neither is.
  Future<void> add({
    required String entityType,
    required String entityId,
    required String operation,
    Map<String, dynamic> payload = const {},
  }) => _db
      .into(_db.pendingMutations)
      .insert(
        PendingMutationsCompanion.insert(
          entityType: entityType,
          entityId: entityId,
          operation: operation,
          payloadJson: jsonEncode(payload),
          createdAt: DateTime.now(),
        ),
      );

  Future<List<PendingMutation>> oldestFirst() => (_db.select(
    _db.pendingMutations,
  )..orderBy([(m) => OrderingTerm.asc(m.id)])).get();

  Future<void> remove(int id) =>
      (_db.delete(_db.pendingMutations)..where((m) => m.id.equals(id))).go();

  Future<void> markAttempt(int id) => _db.customUpdate(
    'UPDATE pending_mutations SET attempts = attempts + 1 WHERE id = ?',
    variables: [Variable.withInt(id)],
    updates: {_db.pendingMutations},
  );

  /// Ids of [entityType] items that still have unsent changes.
  Future<Set<String>> pendingIds(String entityType) async {
    final rows = await (_db.select(
      _db.pendingMutations,
    )..where((m) => m.entityType.equals(entityType))).get();
    return {for (final r in rows) r.entityId};
  }

  Stream<int> watchCount() {
    final count = _db.pendingMutations.id.count();
    return (_db.selectOnly(
      _db.pendingMutations,
    )..addColumns([count])).watchSingle().map((row) => row.read(count) ?? 0);
  }
}
