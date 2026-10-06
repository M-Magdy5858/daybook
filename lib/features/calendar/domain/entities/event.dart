import 'package:daybook/shared/models/recurrence_rule.dart';
import 'package:equatable/equatable.dart';

class Event extends Equatable {
  const Event({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.createdAt,
    this.allDay = false,
    this.colorValue = 0xFF1E88E5,
    this.recurrence,
    this.excludedDates = const {},
    this.linkedTaskId,
    DateTime? updatedAt,
    this.version = 0,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool allDay;

  /// An ARGB color, e.g. `0xFF1E88E5`.
  final int colorValue;
  final RecurrenceRule? recurrence;

  /// Days (midnight) removed from a repeating series, e.g. after moving just
  /// one occurrence.
  final Set<DateTime> excludedDates;

  /// The task this event was scheduled from, if any.
  final String? linkedTaskId;

  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  Duration get duration => end.difference(start);

  Event copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    bool? allDay,
    int? colorValue,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
    Set<DateTime>? excludedDates,
    DateTime? updatedAt,
    int? version,
  }) => Event(
    id: id,
    createdAt: createdAt,
    linkedTaskId: linkedTaskId,
    title: title ?? this.title,
    start: start ?? this.start,
    end: end ?? this.end,
    allDay: allDay ?? this.allDay,
    colorValue: colorValue ?? this.colorValue,
    recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
    excludedDates: excludedDates ?? this.excludedDates,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    start,
    end,
    allDay,
    colorValue,
    recurrence,
    excludedDates,
    linkedTaskId,
    createdAt,
    updatedAt,
    version,
  ];
}

/// One appearance of an [Event] on the calendar. A repeating event has one
/// per date it repeats on.
class EventOccurrence extends Equatable {
  const EventOccurrence({
    required this.event,
    required this.start,
    required this.end,
  });

  final Event event;
  final DateTime start;
  final DateTime end;

  bool get isRepeating => event.recurrence != null;

  @override
  List<Object?> get props => [event, start, end];
}
