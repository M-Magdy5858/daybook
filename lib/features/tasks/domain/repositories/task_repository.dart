import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';

abstract interface class TaskRepository {
  /// Every task, re-emitted whenever any of them changes.
  Stream<List<Task>> watchTasks();

  /// How many local changes are still waiting to reach the server.
  Stream<int> watchPendingChanges();

  Future<Result<List<Task>>> getAll();
  Future<Result<Task>> getById(String id);
  Future<Result<void>> save(Task task);
  Future<Result<void>> delete(String id);

  /// Push waiting changes and pull fresh data from the server.
  Future<Result<void>> refresh();

  /// Fetch this collection's latest copies from the server, nothing else.
  Future<Result<void>> pull();
}
