import 'package:drift/drift.dart';

/// Added in schema v5.
@DataClassName('HabitRow')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get colorValue => integer()();

  /// A JSON list of weekdays, e.g. `[1,3,5]`.
  TextColumn get weekdaysJson => text()();
  IntColumn get reminderMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per day a habit was done. Added in schema v5.
@DataClassName('HabitCompletionRow')
class HabitCompletions extends Table {
  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// The day, as `yyyy-MM-dd`, so there's no time to get wrong.
  TextColumn get day => text()();

  @override
  Set<Column> get primaryKey => {habitId, day};
}
