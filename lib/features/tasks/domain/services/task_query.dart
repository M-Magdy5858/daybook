import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:equatable/equatable.dart';

enum TaskFilter { all, active, completed, overdue, today }

enum TaskSort { manual, dueDate, priority, createdAt }

class TaskQuery extends Equatable {
  const TaskQuery({
    this.filter = TaskFilter.all,
    this.sort = TaskSort.manual,
    this.search = '',
  });

  final TaskFilter filter;
  final TaskSort sort;
  final String search;

  /// A new sorted list of the tasks that match. Never sorts [tasks] in place.
  List<Task> apply(List<Task> tasks, DateTime now) =>
      tasks.where((t) => _matches(t, now)).toList()..sort(_compare);

  TaskQuery copyWith({TaskFilter? filter, TaskSort? sort, String? search}) =>
      TaskQuery(
        filter: filter ?? this.filter,
        sort: sort ?? this.sort,
        search: search ?? this.search,
      );

  bool _matches(Task t, DateTime now) {
    final passesFilter = switch (filter) {
      TaskFilter.all => true,
      TaskFilter.active => !t.isCompleted,
      TaskFilter.completed => t.isCompleted,
      TaskFilter.overdue => t.isOverdue(now),
      TaskFilter.today => !t.isCompleted && _isSameDay(t.dueDate, now),
    };
    if (!passesFilter) return false;

    final q = search.trim().toLowerCase();
    return q.isEmpty ||
        t.title.toLowerCase().contains(q) ||
        t.notes.toLowerCase().contains(q);
  }

  int _compare(Task a, Task b) => switch (sort) {
    TaskSort.manual => a.position.compareTo(b.position),
    TaskSort.priority => b.priority.weight.compareTo(a.priority.weight),
    TaskSort.createdAt => b.createdAt.compareTo(a.createdAt),
    TaskSort.dueDate => switch ((a.dueDate, b.dueDate)) {
      (null, null) => 0,
      (null, _) => 1, // no due date goes last
      (_, null) => -1,
      (final x?, final y?) => x.compareTo(y),
    },
  };

  static bool _isSameDay(DateTime? d, DateTime now) =>
      d != null &&
      d.year == now.year &&
      d.month == now.month &&
      d.day == now.day;

  @override
  List<Object?> get props => [filter, sort, search];
}
