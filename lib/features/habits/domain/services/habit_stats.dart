import 'package:daybook/features/habits/domain/entities/habit.dart';

/// Streaks and rates. Only *scheduled* days count: skipping a day the habit
/// isn't scheduled on never breaks a streak. Pure Dart; `today` is passed in
/// so results are repeatable.
abstract final class HabitStats {
  /// Done scheduled days in a row, counting back from today. If today isn't
  /// done yet, the streak still counts from yesterday.
  static int currentStreak(Habit habit, DateTime today) {
    var day = _day(today);
    if (habit.isScheduledOn(day) && !habit.isDoneOn(day)) day = _prev(day);
    var streak = 0;
    for (final d in _back(day, _start(habit))) {
      if (!habit.isScheduledOn(d)) continue;
      if (!habit.isDoneOn(d)) break;
      streak++;
    }
    return streak;
  }

  /// The longest run of done scheduled days, up to today.
  static int bestStreak(Habit habit, DateTime today) {
    var best = 0;
    var run = 0;
    final end = _day(today);
    for (var d = _start(habit); !d.isAfter(end); d = _next(d)) {
      if (!habit.isScheduledOn(d)) continue;
      if (habit.isDoneOn(d)) {
        run++;
        if (run > best) best = run;
      } else if (d != end) {
        run = 0; // today not done yet doesn't end a run
      }
    }
    return best;
  }

  /// Share of scheduled days in `[from, to]` that were done, 0.0 to 1.0.
  static double completionRate(Habit habit, DateTime from, DateTime to) {
    var scheduled = 0;
    var done = 0;
    for (var d = _day(from); !d.isAfter(_day(to)); d = _next(d)) {
      if (!habit.isScheduledOn(d)) continue;
      scheduled++;
      if (habit.isDoneOn(d)) done++;
    }
    return scheduled == 0 ? 0 : done / scheduled;
  }

  /// Where history starts: creation, or an earlier completion if one exists.
  static DateTime _start(Habit habit) {
    var start = _day(habit.createdAt);
    for (final c in habit.completions) {
      if (c.isBefore(start)) start = c;
    }
    return start;
  }

  static Iterable<DateTime> _back(DateTime from, DateTime start) sync* {
    for (var d = from; !d.isBefore(start); d = _prev(d)) {
      yield d;
    }
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _next(DateTime d) => DateTime(d.year, d.month, d.day + 1);
  static DateTime _prev(DateTime d) => DateTime(d.year, d.month, d.day - 1);
}
