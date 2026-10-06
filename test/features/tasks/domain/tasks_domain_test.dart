import 'package:daybook/features/tasks/data/repositories/in_memory_task_repository.dart';
import 'package:daybook/features/tasks/domain/entities/priority.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/shared/services/recurrence_calculator.dart';
import 'package:daybook/features/tasks/domain/services/task_query.dart';
import 'package:daybook/features/tasks/domain/usecases/complete_task.dart';
import 'package:daybook/shared/models/recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calc = RecurrenceCalculator();

  group('RecurrenceCalculator', () {
    test('Monthly(31) clamps to the last day of shorter months', () {
      expect(
        calc.next(const Monthly(31), DateTime(2027, 1, 31)),
        DateTime(2027, 2, 28),
      );
      expect(
        calc.next(const Monthly(31), DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29),
      );
    });

    test('Weekly wraps from Sunday to Monday', () {
      // 2026-10-11 is a Sunday.
      expect(
        calc.next(const Weekly({DateTime.monday}), DateTime(2026, 10, 11)),
        DateTime(2026, 10, 12),
      );
    });
  });

  test(
    'TaskQuery filters, searches case-insensitively and sorts by priority',
    () {
      final now = DateTime(2026, 10, 6, 12);
      final tasks = [
        Task(
          id: '1',
          title: 'Buy MILK',
          createdAt: now,
          priority: Priority.low,
        ),
        Task(
          id: '2',
          title: 'milk run',
          createdAt: now,
          priority: Priority.high,
        ),
        Task(id: '3', title: 'milk done', createdAt: now, completedAt: now),
      ];
      const query = TaskQuery(
        filter: TaskFilter.active,
        sort: TaskSort.priority,
        search: 'milk',
      );
      expect(query.apply(tasks, now).map((t) => t.id), ['2', '1']);
    },
  );

  test(
    'completing a recurring task creates exactly one next occurrence',
    () async {
      final now = DateTime(2026, 10, 6);
      final repo = InMemoryTaskRepository([
        Task(
          id: '1',
          title: 'Gym',
          createdAt: now,
          dueDate: now,
          recurrence: const Daily(),
        ),
      ]);
      final complete = CompleteTask(repo, newId: () => '2');

      await complete(
        (await repo.getById('1')).fold((t) => t, (_) => throw StateError('')),
        now: now,
      );

      final all = (await repo.getAll()).fold((t) => t, (_) => <Task>[]);
      expect(all, hasLength(2));
      expect(all.firstWhere((t) => t.id == '1').isCompleted, isTrue);
      expect(all.firstWhere((t) => t.id == '2').dueDate, DateTime(2026, 10, 7));
    },
  );
}
