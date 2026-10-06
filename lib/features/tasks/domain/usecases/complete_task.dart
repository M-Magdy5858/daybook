import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';
import 'package:daybook/shared/services/recurrence_calculator.dart';

/// Toggles a task done/not done. Completing a recurring task also creates its
/// next occurrence.
class CompleteTask {
  const CompleteTask(this._repository, {required this.newId});
  final TaskRepository _repository;

  /// Makes ids for new occurrences (injected so tests are repeatable).
  final String Function() newId;

  static const _calculator = RecurrenceCalculator();

  Future<Result<void>> call(Task task, {required DateTime now}) async {
    if (task.isCompleted) {
      return _repository.save(
        task.copyWith(clearCompleted: true, updatedAt: now),
      );
    }

    final saved = await _repository.save(
      task.copyWith(completedAt: now, updatedAt: now),
    );
    final rule = task.recurrence;
    if (saved is Err || rule == null) return saved;

    final next = Task(
      id: newId(),
      title: task.title,
      notes: task.notes,
      priority: task.priority,
      recurrence: rule,
      position: task.position,
      estimatedMinutes: task.estimatedMinutes,
      subtasks: [for (final s in task.subtasks) s.copyWith(done: false)],
      dueDate: _calculator.next(rule, task.dueDate ?? now),
      createdAt: now,
    );
    return _repository.save(next);
  }
}
