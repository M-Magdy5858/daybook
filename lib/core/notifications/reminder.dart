import 'package:equatable/equatable.dart';

/// Notification channels. On Android users can mute each one separately.
enum ReminderChannel {
  tasks('Tasks', 'Reminders for task due times'),
  events('Events', 'Reminders before calendar events'),
  habits('Habits', 'Daily habit reminders');

  const ReminderChannel(this.title, this.description);
  final String title;
  final String description;
}

/// How a reminder repeats after it first fires at `when`.
enum ReminderRepeat {
  none,

  /// Every day at the same time.
  daily,

  /// Every week on the same weekday and time.
  weekly,
}

/// A notification the app wants shown at [when]. Features turn their items
/// into reminders; the [ReminderScheduler] keeps the device in step.
class Reminder extends Equatable {
  const Reminder({
    required this.key,
    required this.title,
    required this.body,
    required this.when,
    required this.link,
    required this.channel,
    this.repeat = ReminderRepeat.none,
  });

  /// Unique and stable for the same item, e.g. `task:abc123`.
  final String key;
  final String title;
  final String body;
  final DateTime when;

  /// A `daybook://` deep link opened when the notification is tapped.
  final String link;
  final ReminderChannel channel;
  final ReminderRepeat repeat;

  /// The platform needs an int id. `String.hashCode` isn't promised to stay
  /// the same between app runs, so use our own hash (FNV-1a, 31 bits): the
  /// same key always gives the same id, so the reminder can be cancelled
  /// later.
  int get notificationId => notificationIdFor(key);

  static int notificationIdFor(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  @override
  List<Object?> get props => [key, title, body, when, link, channel, repeat];
}
