import 'dart:convert';

import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/features/tasks/data/models/recurrence_json.dart';
import 'package:daybook/features/tasks/domain/entities/priority.dart';
import 'package:daybook/features/tasks/domain/entities/subtask.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:drift/drift.dart';

/// Reads and writes tasks in SQLite. The only class that converts between
/// Drift rows and [Task] entities.
class TaskLocalDataSource {
  TaskLocalDataSource(this._db);
  final AppDatabase _db;

  static const _recurrence = RecurrenceJson();

  Stream<List<Task>> watchAll() {
    // Re-run whenever either table changes, so ticking a subtask updates too.
    final query = _db.select(_db.tasks).join([
      leftOuterJoin(_db.subtasks, _db.subtasks.taskId.equalsExp(_db.tasks.id)),
    ])..orderBy([OrderingTerm.asc(_db.subtasks.sortOrder)]);
    return query.watch().map(_toEntities);
  }

  Future<List<Task>> getAll() => watchAll().first;

  Future<Task?> getById(String id) async {
    final row = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final subtasks =
        await (_db.select(_db.subtasks)
              ..where((s) => s.taskId.equals(id))
              ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
            .get();
    return _toEntity(row, subtasks);
  }

  Future<void> upsertAll(List<Task> tasks) => _db.transaction(() async {
    for (final t in tasks) {
      await _db.into(_db.tasks).insertOnConflictUpdate(_toCompanion(t));
      await (_db.delete(
        _db.subtasks,
      )..where((s) => s.taskId.equals(t.id))).go();
      for (final (i, s) in t.subtasks.indexed) {
        await _db
            .into(_db.subtasks)
            .insert(
              SubtasksCompanion.insert(
                id: s.id,
                taskId: t.id,
                title: s.title,
                done: Value(s.done),
                sortOrder: Value(i),
              ),
            );
      }
    }
  });

  Future<void> upsert(Task t) => upsertAll([t]);

  Future<void> delete(String id) =>
      (_db.delete(_db.tasks)..where((r) => r.id.equals(id))).go();

  /// Records the server's version after it accepted a change, without
  /// touching any newer local edits.
  Future<void> setVersion(String id, int version) =>
      (_db.update(_db.tasks)..where((r) => r.id.equals(id))).write(
        TasksCompanion(version: Value(version)),
      );

  List<Task> _toEntities(List<TypedResult> rows) {
    final tasks = <String, TaskRow>{};
    final subtasks = <String, List<SubtaskRow>>{};
    for (final row in rows) {
      final task = row.readTable(_db.tasks);
      tasks[task.id] = task;
      final sub = row.readTableOrNull(_db.subtasks);
      (subtasks[task.id] ??= []).addAll([?sub]);
    }
    return [
      for (final t in tasks.values) _toEntity(t, subtasks[t.id] ?? const []),
    ];
  }

  Task _toEntity(TaskRow row, List<SubtaskRow> subtasks) => Task(
    id: row.id,
    title: row.title,
    notes: row.notes,
    priority: Priority.values.firstWhere(
      (p) => p.weight == row.priority,
      orElse: () => Priority.medium,
    ),
    dueDate: row.dueDate,
    completedAt: row.completedAt,
    recurrence: row.recurrenceJson == null
        ? null
        : _recurrence.fromJson(
            jsonDecode(row.recurrenceJson!) as Map<String, dynamic>,
          ),
    position: row.position,
    estimatedMinutes: row.estimatedMinutes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    version: row.version,
    subtasks: [
      for (final s in subtasks) Subtask(id: s.id, title: s.title, done: s.done),
    ],
  );

  TasksCompanion _toCompanion(Task t) => TasksCompanion.insert(
    id: t.id,
    title: t.title,
    notes: Value(t.notes),
    priority: Value(t.priority.weight),
    dueDate: Value(t.dueDate),
    completedAt: Value(t.completedAt),
    recurrenceJson: Value(
      t.recurrence == null
          ? null
          : jsonEncode(_recurrence.toJson(t.recurrence)),
    ),
    position: Value(t.position),
    estimatedMinutes: Value(t.estimatedMinutes),
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    version: Value(t.version),
  );
}
