import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';

class WatchTasks {
  const WatchTasks(this._repository);
  final TaskRepository _repository;

  Stream<List<Task>> call() => _repository.watchTasks();
  Stream<int> pendingChanges() => _repository.watchPendingChanges();
}
