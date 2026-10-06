import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/shared/services/recurrence_calculator.dart';

/// Turns events into the occurrences that fall in a date range.
class OccurrenceExpander {
  const OccurrenceExpander();

  static const _calculator = RecurrenceCalculator();

  /// Guards against runaway series (e.g. a daily event from years ago).
  static const _maxSteps = 5000;

  /// Occurrences overlapping `[from, to)`, sorted by start.
  List<EventOccurrence> expand(List<Event> events, DateTime from, DateTime to) {
    final result = <EventOccurrence>[];
    for (final event in events) {
      final rule = event.recurrence;
      var start = event.start;
      for (var i = 0; i < _maxSteps && start.isBefore(to); i++) {
        final end = start.add(event.duration);
        final excluded = event.excludedDates.contains(
          DateTime(start.year, start.month, start.day),
        );
        if (end.isAfter(from) && !excluded) {
          result.add(EventOccurrence(event: event, start: start, end: end));
        }
        if (rule == null) break;
        start = _calculator.next(rule, start);
      }
    }
    return result..sort((a, b) => a.start.compareTo(b.start));
  }
}
