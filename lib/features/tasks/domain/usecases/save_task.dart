import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';
import 'package:daybook/features/tasks/domain/services/task_validator.dart';

/// Creates or updates a task after validating it.
class SaveTask {
  const SaveTask(this._repository);
  final TaskRepository _repository;

  Future<Result<void>> call(Task task, {required DateTime now}) {
    final problems = TaskValidator.validate(task);
    if (problems.isNotEmpty) {
      return Future.value(
        Err(
          ValidationFailure(
            'Please fix the task',
            fieldErrors: {for (final p in problems) _field(p): _message(p)},
          ),
        ),
      );
    }
    return _repository.save(
      task.copyWith(title: task.title.trim(), updatedAt: now),
    );
  }

  static String _field(TaskProblem p) => switch (p) {
    TaskProblem.titleEmpty || TaskProblem.titleTooLong => 'title',
    TaskProblem.invalidInterval || TaskProblem.noWeekdays => 'recurrence',
  };

  static String _message(TaskProblem p) => switch (p) {
    TaskProblem.titleEmpty => 'Required',
    TaskProblem.titleTooLong =>
      'At most ${TaskValidator.maxTitleLength} characters',
    TaskProblem.invalidInterval => 'Repeat at least every 1 day',
    TaskProblem.noWeekdays => 'Pick at least one day',
  };
}
