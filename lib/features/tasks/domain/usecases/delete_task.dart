import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';

class DeleteTask {
  const DeleteTask(this._repository);
  final TaskRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}
