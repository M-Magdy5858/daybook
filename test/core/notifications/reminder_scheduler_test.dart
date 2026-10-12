import 'dart:async';

import 'package:daybook/core/notifications/notification_service.dart';
import 'package:daybook/core/notifications/reminder.dart';
import 'package:daybook/core/notifications/reminder_scheduler.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/presentation/task_reminders.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotifications implements NotificationService {
  final scheduled = <int, Reminder>{};
  final log = <String>[];

  @override
  Future<void> schedule(Reminder r) async {
    scheduled[r.notificationId] = r;
    log.add('schedule ${r.key}');
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    log.add('cancel $id');
  }

  @override
  Future<Set<int>> pendingIds() async => scheduled.keys.toSet();
  @override
  Future<void> init({required void Function(String) onTap}) async {}
  @override
  Future<String?> takeLaunchLink() async => null;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> showNow(Reminder r) async {}
}

void main() {
  test('schedules once, reschedules on edit, cancels on complete', () async {
    final notifications = FakeNotifications();
    final tasks = StreamController<List<Task>>.broadcast();
    final scheduler = ReminderScheduler(
      notifications,
      sources: [() => tasks.stream.map(taskReminders)],
    );
    await scheduler.start();
    final due = DateTime.now().add(const Duration(days: 1));
    final task = Task(
      id: '1',
      title: 'Pay rent',
      createdAt: DateTime(2026),
      dueDate: due,
    );
    final id = Reminder.notificationIdFor('task:1');

    Future<void> emit(List<Task> list) async {
      tasks.add(list);
      await pumpEventQueue();
    }

    await emit([task]);
    await emit([task]); // unchanged: no second schedule
    expect(notifications.log, ['schedule task:1']);
    expect(notifications.scheduled[id]!.link, 'daybook://task/1');

    await emit([task.copyWith(dueDate: due.add(const Duration(hours: 1)))]);
    expect(notifications.log.last, 'schedule task:1');

    await emit([task.copyWith(completedAt: DateTime.now())]);
    expect(notifications.log.last, 'cancel $id');
    expect(notifications.scheduled, isEmpty);

    await scheduler.stop();
    await tasks.close();
  });
}
