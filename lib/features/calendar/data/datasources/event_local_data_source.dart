import 'dart:convert';

import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/features/calendar/data/models/event_model.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/shared/models/recurrence_json.dart';
import 'package:drift/drift.dart';

/// Reads and writes events in SQLite. The only class that converts between
/// Drift rows and [Event] entities.
class EventLocalDataSource {
  EventLocalDataSource(this._db);
  final AppDatabase _db;

  static const _recurrence = RecurrenceJson();

  Stream<List<Event>> watchAll() => _db
      .select(_db.events)
      .watch()
      .map((rows) => [for (final r in rows) _toEntity(r)]);

  Future<Event?> getById(String id) async {
    final row = await (_db.select(
      _db.events,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  Future<void> upsertAll(List<Event> events) => _db.transaction(() async {
    for (final e in events) {
      await _db.into(_db.events).insertOnConflictUpdate(_toCompanion(e));
    }
  });

  Future<void> upsert(Event e) => upsertAll([e]);

  Future<void> delete(String id) =>
      (_db.delete(_db.events)..where((e) => e.id.equals(id))).go();

  Future<void> setVersion(String id, int version) =>
      (_db.update(_db.events)..where((e) => e.id.equals(id))).write(
        EventsCompanion(version: Value(version)),
      );

  Future<Map<String, ({DateTime updatedAt, int version})>> syncInfo() async {
    final rows = await _db.select(_db.events).get();
    return {
      for (final r in rows) r.id: (updatedAt: r.updatedAt, version: r.version),
    };
  }

  Event _toEntity(EventRow r) => Event(
    id: r.id,
    title: r.title,
    start: r.start,
    end: r.end,
    allDay: r.allDay,
    colorValue: r.colorValue,
    recurrence: r.recurrenceJson == null
        ? null
        : _recurrence.fromJson(
            jsonDecode(r.recurrenceJson!) as Map<String, dynamic>,
          ),
    excludedDates: {
      for (final d in jsonDecode(r.excludedDatesJson) as List)
        DateTime.parse(d as String),
    },
    linkedTaskId: r.linkedTaskId,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    version: r.version,
  );

  EventsCompanion _toCompanion(Event e) => EventsCompanion.insert(
    id: e.id,
    title: e.title,
    start: e.start,
    end: e.end,
    allDay: Value(e.allDay),
    colorValue: e.colorValue,
    recurrenceJson: Value(
      e.recurrence == null
          ? null
          : jsonEncode(_recurrence.toJson(e.recurrence)),
    ),
    excludedDatesJson: Value(
      jsonEncode([for (final d in e.excludedDates) EventModel.dayKey(d)]),
    ),
    linkedTaskId: Value(e.linkedTaskId),
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
    version: Value(e.version),
  );
}
