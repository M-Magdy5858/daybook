import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';
import 'package:daybook/features/tasks/domain/services/task_query.dart';

class GetTasks {
  const GetTasks(this._repository);
  final TaskRepository _repository;

  Future<Result<List<Task>>> call(
    TaskQuery query, {
    required DateTime now,
  }) async => switch (await _repository.getAll()) {
    Success(:final data) => Success(query.apply(data, now)),
    Err(:final failure) => Err(failure),
  };
}
