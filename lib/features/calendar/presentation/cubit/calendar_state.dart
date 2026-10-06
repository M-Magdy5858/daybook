import 'package:daybook/core/error/failures.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:equatable/equatable.dart';

enum CalendarView { month, week, day, agenda }

enum CalendarStatus { loading, ready }

class CalendarState extends Equatable {
  const CalendarState({
    required this.focused,
    required this.selected,
    this.view = CalendarView.month,
    this.status = CalendarStatus.loading,
    this.events = const [],
    this.occurrences = const [],
    this.failure,
  });

  factory CalendarState.initial(DateTime now) =>
      CalendarState(focused: now.startOfDay, selected: now.startOfDay);

  final CalendarView view;

  /// The date the current view is built around.
  final DateTime focused;

  /// The day the user picked; new events start on it.
  final DateTime selected;
  final CalendarStatus status;
  final List<Event> events;

  /// [events] expanded over [range], sorted by start.
  final List<EventOccurrence> occurrences;

  /// The latest error to show once. Cleared by the next [copyWith].
  final Failure? failure;

  /// The dates the current view shows: `[from, to)`.
  (DateTime from, DateTime to) get range => switch (view) {
    // Six full weeks starting on the Monday before the 1st.
    CalendarView.month => (
      focused.startOfMonth.startOfWeek,
      focused.startOfMonth.startOfWeek.addDays(42),
    ),
    CalendarView.week => (focused.startOfWeek, focused.startOfWeek.addDays(7)),
    CalendarView.day => (focused.startOfDay, focused.startOfDay.addDays(1)),
    CalendarView.agenda => (focused.startOfDay, focused.startOfDay.addDays(30)),
  };

  List<EventOccurrence> on(DateTime day) => [
    for (final o in occurrences)
      if (o.start.isBefore(day.startOfDay.addDays(1)) &&
          o.end.isAfter(day.startOfDay))
        o,
  ];

  CalendarState copyWith({
    CalendarView? view,
    DateTime? focused,
    DateTime? selected,
    CalendarStatus? status,
    List<Event>? events,
    List<EventOccurrence>? occurrences,
    Failure? failure,
  }) => CalendarState(
    view: view ?? this.view,
    focused: focused ?? this.focused,
    selected: selected ?? this.selected,
    status: status ?? this.status,
    events: events ?? this.events,
    occurrences: occurrences ?? this.occurrences,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    view,
    focused,
    selected,
    status,
    events,
    occurrences,
    failure,
  ];
}
