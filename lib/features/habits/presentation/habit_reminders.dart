import 'package:daybook/core/notifications/reminder.dart';
import 'package:daybook/core/routing/deep_link_parser.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';

/// Repeating reminders for habits that have a reminder time: one daily
/// reminder for an every-day habit, or one weekly reminder per scheduled
/// weekday otherwise.
List<Reminder> habitReminders(List<Habit> habits, DateTime now) => [
  for (final h in habits)
    if (h.reminderMinutes case final minutes?)
      if (h.isEveryDay)
        _reminder(
          h,
          'habit:${h.id}',
          _nextAt(now, minutes),
          ReminderRepeat.daily,
        )
      else
        for (final weekday in h.weekdays)
          _reminder(
            h,
            'habit:${h.id}:$weekday',
            _nextAt(now, minutes, weekday: weekday),
            ReminderRepeat.weekly,
          ),
];

Reminder _reminder(Habit h, String key, DateTime when, ReminderRepeat repeat) =>
    Reminder(
      key: key,
      title: h.name,
      body: "Time for today's habit",
      when: when,
      link: DeepLinks.habit(h.id),
      channel: ReminderChannel.habits,
      repeat: repeat,
    );

/// The next time it's [minutes] past midnight (on [weekday], if given),
/// strictly after [now].
DateTime _nextAt(DateTime now, int minutes, {int? weekday}) {
  for (var i = 0; i <= 7; i++) {
    final day = DateTime(now.year, now.month, now.day + i);
    final at = DateTime(
      day.year,
      day.month,
      day.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (at.isAfter(now) && (weekday == null || day.weekday == weekday)) {
      return at;
    }
  }
  throw StateError('unreachable: every weekday comes within 8 days');
}
