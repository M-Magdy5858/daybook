import 'dart:async';

import 'package:daybook/core/error/error_mapper.dart';
import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/core/storage/outbox.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:daybook/features/tasks/data/models/task_model.dart';
import 'package:daybook/core/sync/sync_engine.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/repositories/task_repository.dart';

/// Local-first: reads come from SQLite, writes go to SQLite plus the outbox,
/// and the [SyncEngine] delivers them to the server.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required this._db,
    required this._local,
    required this._outbox,
    required this._sync,
  });

  final AppDatabase _db;
  final TaskLocalDataSource _local;
  final Outbox _outbox;
  final SyncEngine _sync;

  @override
  Stream<List<Task>> watchTasks() => _local.watchAll();

  @override
  Stream<int> watchPendingChanges() => _outbox.watchCount();

  @override
  Future<Result<List<Task>>> getAll() => _guard(_local.getAll);

  @override
  Future<Result<Task>> getById(String id) => _guard(() async {
    final task = await _local.getById(id);
    if (task == null) throw const NotFoundException('Task not found');
    return task;
  });

  @override
  Future<Result<void>> save(Task task) => _guard(() async {
    await _db.transaction(() async {
      final exists = await _local.getById(task.id) != null;
      await _local.upsert(task);
      await _outbox.add(
        entityType: 'task',
        entityId: task.id,
        operation: exists ? 'update' : 'create',
        payload: TaskModel.fromEntity(task).toJson(),
      );
    }); // if either write fails, neither is kept
    unawaited(_sync.syncNow());
  });

  @override
  Future<Result<void>> delete(String id) => _guard(() async {
    await _db.transaction(() async {
      await _local.delete(id);
      await _outbox.add(entityType: 'task', entityId: id, operation: 'delete');
    });
    unawaited(_sync.syncNow());
  });

  @override
  Future<Result<void>> refresh() => _sync.syncNow();

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Success(await body());
    } on AppException catch (e) {
      return Err(ErrorMapper.toFailure(e));
    } catch (_) {
      return const Err(CacheFailure());
    }
  }
}
