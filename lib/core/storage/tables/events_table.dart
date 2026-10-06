import 'package:drift/drift.dart';

/// Added in schema v4.
@DataClassName('EventRow')
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  IntColumn get colorValue => integer()();
  TextColumn get recurrenceJson => text().nullable()();

  /// A JSON list of `yyyy-MM-dd` days removed from a repeating series.
  TextColumn get excludedDatesJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get linkedTaskId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get version => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
