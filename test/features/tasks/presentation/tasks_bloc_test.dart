import 'package:daybook/features/tasks/data/repositories/in_memory_task_repository.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/usecases/complete_task.dart';
import 'package:daybook/features/tasks/domain/usecases/delete_task.dart';
import 'package:daybook/features/tasks/domain/usecases/refresh_tasks.dart';
import 'package:daybook/features/tasks/domain/usecases/save_task.dart';
import 'package:daybook/features/tasks/domain/usecases/watch_tasks.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delete then undo brings the task back', () async {
    final task = Task(id: '1', title: 'Buy milk', createdAt: DateTime(2026));
    final repo = InMemoryTaskRepository([task]);
    final bloc = TasksBloc(
      watchTasks: WatchTasks(repo),
      saveTask: SaveTask(repo),
      deleteTask: DeleteTask(repo),
      completeTask: CompleteTask(repo, newId: () => 'x'),
      refreshTasks: RefreshTasks(repo),
    )..add(const TasksSubscribed());
    addTearDown(bloc.close);

    await bloc.stream.firstWhere((s) => s.status == TasksStatus.success);
    bloc.add(const TaskDeleted('1'));
    await bloc.stream.firstWhere((s) => s.byId('1') == null);
    bloc.add(TaskRestored(task));
    final restored = await bloc.stream.firstWhere((s) => s.byId('1') != null);

    expect(restored.byId('1')!.title, 'Buy milk');
  });
}
