import 'package:daybook/core/network/api_client.dart';
import 'package:daybook/features/tasks/data/models/paginated_response.dart';
import 'package:daybook/features/tasks/data/models/task_model.dart';

class TaskRemoteDataSource {
  TaskRemoteDataSource(this._api);
  final ApiClient _api;

  static const pageSize = 20;

  Future<PaginatedResponse<TaskModel>> fetchPage(
    int page, {
    DateTime? updatedSince,
  }) async => PaginatedResponse.fromJson(
    await _api.get(
      '/tasks',
      query: {
        'page': page,
        'limit': pageSize,
        if (updatedSince != null)
          'updatedSince': updatedSince.toUtc().toIso8601String(),
      },
    ),
    TaskModel.fromJson,
  );

  Future<TaskModel> create(TaskModel task) async =>
      TaskModel.fromJson(await _api.post('/tasks', body: task.toJson()));

  /// Sends [task.version] so the server can detect conflicts (409).
  Future<TaskModel> update(TaskModel task) async => TaskModel.fromJson(
    await _api.patch('/tasks/${task.id}', body: task.toJson()),
  );

  Future<void> delete(String id) => _api.delete('/tasks/$id');
}
