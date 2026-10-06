import 'dart:convert';

import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:daybook/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:daybook/features/tasks/data/models/task_model.dart';

/// Last-write-wins: whichever copy was edited more recently is kept.
class ConflictResolver {
  ConflictResolver({required this._local, required this._remote});

  final TaskLocalDataSource _local;
  final TaskRemoteDataSource _remote;

  /// [serverTask] is the server's copy from the 409 response.
  Future<void> resolve({
    required PendingMutation local,
    required Map<String, dynamic> serverTask,
  }) async {
    final server = TaskModel.fromJson(serverTask);
    final mine = TaskModel.fromJson(
      jsonDecode(local.payloadJson) as Map<String, dynamic>,
    );

    if (server.updatedAt.isAfter(mine.updatedAt)) {
      await _local.upsert(server.toEntity()); // the server wins
      return;
    }
    // Ours wins: send it again, now based on the server's version.
    final saved = await _remote.update(
      TaskModel.fromJson({...mine.toJson(), 'version': server.version}),
    );
    await _local.setVersion(saved.id, saved.version);
  }
}
