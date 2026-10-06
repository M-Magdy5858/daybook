import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';

class RefreshTasks {
  const RefreshTasks(this._repository);
  final TaskRepository _repository;

  Future<Result<void>> call() => _repository.refresh();
}
