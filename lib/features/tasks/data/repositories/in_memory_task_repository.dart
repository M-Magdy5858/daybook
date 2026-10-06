import 'dart:async';

import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';

/// A [TaskRepository] backed by a map. Handy in tests.
class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository([List<Task> seed = const []])
    : _tasks = {for (final t in seed) t.id: t};

  final Map<String, Task> _tasks;
  final _changes = StreamController<List<Task>>.broadcast();

  List<Task> get _all => List.unmodifiable(_tasks.values);

  @override
  Stream<List<Task>> watchTasks() async* {
    yield _all;
    yield* _changes.stream;
  }

  @override
  Stream<int> watchPendingChanges() => Stream.value(0);

  @override
  Future<Result<List<Task>>> getAll() async => Success(_all);

  @override
  Future<Result<Task>> getById(String id) async {
    final task = _tasks[id];
    return task == null ? const Err(NotFoundFailure()) : Success(task);
  }

  @override
  Future<Result<void>> save(Task task) async {
    _tasks[task.id] = task;
    _changes.add(_all);
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    _tasks.remove(id);
    _changes.add(_all);
    return const Success(null);
  }

  @override
  Future<Result<void>> refresh() async => const Success(null);
}
