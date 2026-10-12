import 'package:daybook/core/notifications/reminder.dart';
import 'package:daybook/core/routing/deep_link_parser.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/calendar/domain/services/occurrence_expander.dart';

const _before = Duration(minutes: 15);
const _lookAhead = Duration(days: 60);

/// A reminder 15 minutes before each event's next occurrence. All-day events
/// have no start time, so they get none.
List<Reminder> eventReminders(List<Event> events, DateTime now) {
  final next = <String, EventOccurrence>{};
  for (final o in const OccurrenceExpander().expand(
    [
      for (final e in events)
        if (!e.allDay) e,
    ],
    now.add(_before),
    now.add(_lookAhead),
  )) {
    next.putIfAbsent(o.event.id, () => o); // sorted, so the first is soonest
  }
  return [
    for (final o in next.values)
      if (o.start.isAfter(now.add(_before)))
        Reminder(
          key: 'event:${o.event.id}',
          title: o.event.title,
          body: 'Starts in 15 minutes',
          when: o.start.subtract(_before),
          link: DeepLinks.event(o.event.id),
          channel: ReminderChannel.events,
        ),
  ];
}
