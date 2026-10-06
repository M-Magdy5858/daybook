import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/services/task_query.dart';
import 'package:equatable/equatable.dart';

sealed class TasksEvent extends Equatable {
  const TasksEvent();
  @override
  List<Object?> get props => [];
}

/// Start listening to the local database (and refresh from the server).
final class TasksSubscribed extends TasksEvent {
  const TasksSubscribed();
}

/// Sync with the server (pull to refresh).
final class TasksRefreshed extends TasksEvent {
  const TasksRefreshed();
}

final class TaskSaved extends TasksEvent {
  const TaskSaved(this.task);
  final Task task;
  @override
  List<Object?> get props => [task];
}

final class TaskDeleted extends TasksEvent {
  const TaskDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

/// Undo a delete.
final class TaskRestored extends TasksEvent {
  const TaskRestored(this.task);
  final Task task;
  @override
  List<Object?> get props => [task];
}

final class TaskToggled extends TasksEvent {
  const TaskToggled(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

/// Move the item at [oldIndex] of the visible list so it ends up at
/// [newIndex] (as `onReorderItem` reports them).
final class TasksReordered extends TasksEvent {
  const TasksReordered(this.oldIndex, this.newIndex);
  final int oldIndex;
  final int newIndex;
  @override
  List<Object?> get props => [oldIndex, newIndex];
}

final class QueryChanged extends TasksEvent {
  const QueryChanged(this.query);
  final TaskQuery query;
  @override
  List<Object?> get props => [query];
}
