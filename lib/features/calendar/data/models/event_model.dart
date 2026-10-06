import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/shared/models/recurrence_json.dart';
import 'package:daybook/shared/models/recurrence_rule.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_model.g.dart';

/// An event as the API sends it. Dates travel as ISO-8601 strings in UTC.
@JsonSerializable()
class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
    this.allDay = false,
    this.recurrence,
    this.excludedDates = const [],
    this.linkedTaskId,
    this.version = 0,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);

  factory EventModel.fromEntity(Event e) => EventModel(
    id: e.id,
    title: e.title,
    start: e.start.toUtc(),
    end: e.end.toUtc(),
    allDay: e.allDay,
    colorValue: e.colorValue,
    recurrence: e.recurrence,
    excludedDates: [for (final d in e.excludedDates) dayKey(d)]..sort(),
    linkedTaskId: e.linkedTaskId,
    createdAt: e.createdAt.toUtc(),
    updatedAt: e.updatedAt.toUtc(),
    version: e.version,
  );

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final int colorValue;
  @RecurrenceJson()
  final RecurrenceRule? recurrence;

  /// `yyyy-MM-dd` days removed from the series.
  final List<String> excludedDates;
  final String? linkedTaskId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  Event toEntity() => Event(
    id: id,
    title: title,
    start: start.toLocal(),
    end: end.toLocal(),
    allDay: allDay,
    colorValue: colorValue,
    recurrence: recurrence,
    excludedDates: {for (final d in excludedDates) DateTime.parse(d)},
    linkedTaskId: linkedTaskId,
    createdAt: createdAt.toLocal(),
    updatedAt: updatedAt.toLocal(),
    version: version,
  );

  /// `2026-10-06` for a date; the time of day is ignored.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
