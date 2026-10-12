import 'package:daybook/core/notifications/reminder.dart';
import 'package:daybook/core/routing/deep_link_parser.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';

/// One reminder per open task with a due time, at that time.
List<Reminder> taskReminders(List<Task> tasks) => [
  for (final t in tasks)
    if (!t.isCompleted && t.dueDate != null)
      Reminder(
        key: 'task:${t.id}',
        title: t.title,
        body: 'This task is due now',
        when: t.dueDate!,
        link: DeepLinks.task(t.id),
        channel: ReminderChannel.tasks,
      ),
];
