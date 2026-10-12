import 'package:daybook/core/storage/tables/events_table.dart';
import 'package:daybook/core/storage/tables/habits_table.dart';
import 'package:daybook/core/storage/tables/pending_mutations_table.dart';
import 'package:daybook/core/storage/tables/tasks_table.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Tasks, Subtasks, PendingMutations, Events, Habits, HabitCompletions],
)
class AppDatabase extends _$AppDatabase {
  /// Tests pass `NativeDatabase.memory()` for a fresh in-RAM database.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'daybook'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(tasks, tasks.estimatedMinutes);
      if (from < 3) {
        await m.addColumn(tasks, tasks.version);
        await m.createTable(pendingMutations);
      }
      if (from < 4) await m.createTable(events);
      if (from < 5) {
        await m.createTable(habits);
        await m.createTable(habitCompletions);
      }
    },
    // SQLite leaves foreign keys off unless asked, and cascades need them.
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
