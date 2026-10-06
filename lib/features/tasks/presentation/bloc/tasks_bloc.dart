import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/services/task_query.dart';
import 'package:daybook/features/tasks/domain/usecases/complete_task.dart';
import 'package:daybook/features/tasks/domain/usecases/delete_task.dart';
import 'package:daybook/features/tasks/domain/usecases/refresh_tasks.dart';
import 'package:daybook/features/tasks/domain/usecases/save_task.dart';
import 'package:daybook/features/tasks/domain/usecases/watch_tasks.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc({
    required this._watchTasks,
    required this._saveTask,
    required this._deleteTask,
    required this._completeTask,
    required this._refreshTasks,
    DateTime Function() clock = DateTime.now,
  }) : _now = clock,
       super(const TasksState()) {
    on<TasksSubscribed>(_onSubscribed, transformer: restartable());
    on<TasksRefreshed>(_onRefreshed, transformer: droppable());
    on<TaskSaved>((e, emit) => _write(emit, _saveTask(e.task, now: _now())));
    on<TaskRestored>((e, emit) => _write(emit, _saveTask(e.task, now: _now())));
    on<TaskDeleted>(_onDeleted);
    on<TaskToggled>(_onToggled);
    on<TasksReordered>(_onReordered);
    on<QueryChanged>((e, emit) => emit(state.copyWith(query: e.query)));
  }

  final WatchTasks _watchTasks;
  final SaveTask _saveTask;
  final DeleteTask _deleteTask;
  final CompleteTask _completeTask;
  final RefreshTasks _refreshTasks;
  final DateTime Function() _now;

  Future<void> _onSubscribed(
    TasksSubscribed event,
    Emitter<TasksState> emit,
  ) async {
    emit(state.copyWith(status: TasksStatus.loading));
    add(const TasksRefreshed()); // ask the server for fresh data meanwhile
    // The database is the source of truth: every write shows up here.
    await Future.wait([
      emit.forEach<List<Task>>(
        _watchTasks(),
        onData: (tasks) =>
            state.copyWith(status: TasksStatus.success, tasks: tasks),
      ),
      emit.forEach<int>(
        _watchTasks.pendingChanges(),
        onData: (n) => state.copyWith(pendingChanges: n),
      ),
    ]);
  }

  Future<void> _onRefreshed(
    TasksRefreshed event,
    Emitter<TasksState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    final result = await _refreshTasks();
    emit(
      state.copyWith(
        isRefreshing: false,
        failure: result is Err<void> ? result.failure : null,
      ),
    );
  }

  Future<void> _onDeleted(TaskDeleted event, Emitter<TasksState> emit) async {
    // Drop it from the screen right away, so a swiped row disappears at once.
    emit(
      state.copyWith(tasks: [...state.tasks.where((t) => t.id != event.id)]),
    );
    await _write(emit, _deleteTask(event.id));
  }

  Future<void> _onToggled(TaskToggled event, Emitter<TasksState> emit) async {
    final task = state.byId(event.id);
    if (task == null) return;
    await _write(emit, _completeTask(task, now: _now()));
  }

  Future<void> _onReordered(
    TasksReordered event,
    Emitter<TasksState> emit,
  ) async {
    final ordered = state.visible(_now());
    ordered.insert(event.newIndex, ordered.removeAt(event.oldIndex));
    final changed = [
      for (final (i, t) in ordered.indexed)
        if (t.position != i) t.copyWith(position: i),
    ];
    // Show the new order now; the saves below confirm it.
    final byId = {for (final t in changed) t.id: t};
    emit(state.copyWith(tasks: [for (final t in state.tasks) byId[t.id] ?? t]));
    for (final t in changed) {
      await _write(emit, _saveTask(t, now: _now()));
    }
  }

  Future<void> _write(Emitter<TasksState> emit, Future<Result<void>> op) async {
    if (await op case Err(:final failure)) {
      emit(state.copyWith(failure: failure));
    }
  }
}

/// Manual reordering only makes sense when the whole list is visible.
extension TaskQueryReorder on TaskQuery {
  bool get canReorder =>
      sort == TaskSort.manual &&
      filter == TaskFilter.all &&
      search.trim().isEmpty;
}
