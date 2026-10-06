import 'package:daybook/shared/models/recurrence_rule.dart';

/// Works out the next date a recurring item is due. Dates are built with
/// `DateTime(y, m, d + n)` so daylight-saving changes can't shift the day.
class RecurrenceCalculator {
  const RecurrenceCalculator();

  DateTime next(RecurrenceRule rule, DateTime from) => switch (rule) {
    Daily() => _addDays(from, 1),
    EveryNDays(:final n) => _addDays(from, n),
    Weekly(:final weekdays) => _nextWeekday(from, weekdays),
    Monthly(:final day) => _nextMonthly(from, day),
  };

  DateTime _addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n, d.hour, d.minute);

  DateTime _nextWeekday(DateTime from, Set<int> weekdays) {
    for (var i = 1; i <= 7; i++) {
      final date = _addDays(from, i);
      if (weekdays.contains(date.weekday)) return date;
    }
    return _addDays(from, 7); // no weekdays: the validator rejects this
  }

  DateTime _nextMonthly(DateTime from, int day) {
    // Day 0 of a month is the last day of the month before it.
    final lastDayNextMonth = DateTime(from.year, from.month + 2, 0).day;
    return DateTime(
      from.year,
      from.month + 1,
      day > lastDayNextMonth ? lastDayNextMonth : day,
      from.hour,
      from.minute,
    );
  }
}
