import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/shared/models/recurrence_rule.dart';

enum TaskProblem { titleEmpty, titleTooLong, invalidInterval, noWeekdays }

abstract final class TaskValidator {
  static const maxTitleLength = 200;

  /// Every problem with [task]; empty means valid.
  static List<TaskProblem> validate(Task task) {
    final title = task.title.trim();
    return [
      if (title.isEmpty) TaskProblem.titleEmpty,
      if (title.length > maxTitleLength) TaskProblem.titleTooLong,
      ...switch (task.recurrence) {
        EveryNDays(:final n) when n < 1 => [TaskProblem.invalidInterval],
        Weekly(:final weekdays) when weekdays.isEmpty => [
          TaskProblem.noWeekdays,
        ],
        _ => const <TaskProblem>[],
      },
    ];
  }
}
