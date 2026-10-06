import 'package:daybook/core/error/failures.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/services/task_query.dart';
import 'package:equatable/equatable.dart';

enum TasksStatus { initial, loading, success, failure }

class TasksState extends Equatable {
  const TasksState({
    this.status = TasksStatus.initial,
    this.tasks = const [],
    this.query = const TaskQuery(),
    this.failure,
    this.pendingChanges = 0,
    this.isRefreshing = false,
  });

  final TasksStatus status;

  /// Every task; [visible] applies the query.
  final List<Task> tasks;
  final TaskQuery query;

  /// The latest error to show once. Cleared by the next [copyWith].
  final Failure? failure;

  /// Local changes still waiting to reach the server.
  final int pendingChanges;
  final bool isRefreshing;

  List<Task> visible(DateTime now) => query.apply(tasks, now);

  Task? byId(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  TasksState copyWith({
    TasksStatus? status,
    List<Task>? tasks,
    TaskQuery? query,
    Failure? failure,
    int? pendingChanges,
    bool? isRefreshing,
  }) => TasksState(
    status: status ?? this.status,
    tasks: tasks ?? this.tasks,
    query: query ?? this.query,
    failure: failure,
    pendingChanges: pendingChanges ?? this.pendingChanges,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  @override
  List<Object?> get props => [
    status,
    tasks,
    query,
    failure,
    pendingChanges,
    isRefreshing,
  ];
}
