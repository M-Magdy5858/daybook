import 'dart:convert';

import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:drift/drift.dart';

/// Reads and writes habits and their completions in SQLite.
class HabitLocalDataSource {
  HabitLocalDataSource(this._db);
  final AppDatabase _db;

  Stream<List<Habit>> watchAll() {
    // Re-run when either table changes, so ticking a day updates at once.
    final query = _db.select(_db.habits).join([
      leftOuterJoin(
        _db.habitCompletions,
        _db.habitCompletions.habitId.equalsExp(_db.habits.id),
      ),
    ]);
    return query.watch().map(_toEntities);
  }

  Future<Habit?> getById(String id) async =>
      (await watchAll().first).where((h) => h.id == id).firstOrNull;

  Future<void> upsertAll(List<Habit> habits) => _db.transaction(() async {
    for (final h in habits) {
      await _db.into(_db.habits).insertOnConflictUpdate(_toCompanion(h));
      await (_db.delete(
        _db.habitCompletions,
      )..where((c) => c.habitId.equals(h.id))).go();
      await _db.batch(
        (b) => b.insertAll(_db.habitCompletions, [
          for (final d in h.completions)
            HabitCompletionsCompanion.insert(habitId: h.id, day: d.dayKey),
        ]),
      );
    }
  });

  Future<void> upsert(Habit h) => upsertAll([h]);

  Future<void> delete(String id) =>
      (_db.delete(_db.habits)..where((h) => h.id.equals(id))).go();

  Future<void> setVersion(String id, int version) =>
      (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
        HabitsCompanion(version: Value(version)),
      );

  Future<Map<String, ({DateTime updatedAt, int version})>> syncInfo() async {
    final rows = await _db.select(_db.habits).get();
    return {
      for (final r in rows) r.id: (updatedAt: r.updatedAt, version: r.version),
    };
  }

  List<Habit> _toEntities(List<TypedResult> rows) {
    final habits = <String, HabitRow>{};
    final days = <String, Set<DateTime>>{};
    for (final row in rows) {
      final habit = row.readTable(_db.habits);
      habits[habit.id] = habit;
      final done = row.readTableOrNull(_db.habitCompletions);
      (days[habit.id] ??= {}).addAll([?done].map((c) => DateTime.parse(c.day)));
    }
    return [
      for (final h in habits.values)
        Habit(
          id: h.id,
          name: h.name,
          colorValue: h.colorValue,
          weekdays: (jsonDecode(h.weekdaysJson) as List).cast<int>().toSet(),
          reminderMinutes: h.reminderMinutes,
          completions: days[h.id] ?? const {},
          createdAt: h.createdAt,
          updatedAt: h.updatedAt,
          version: h.version,
        ),
    ];
  }

  HabitsCompanion _toCompanion(Habit h) => HabitsCompanion.insert(
    id: h.id,
    name: h.name,
    colorValue: h.colorValue,
    weekdaysJson: jsonEncode(h.weekdays.toList()..sort()),
    reminderMinutes: Value(h.reminderMinutes),
    createdAt: h.createdAt,
    updatedAt: h.updatedAt,
    version: Value(h.version),
  );
}
