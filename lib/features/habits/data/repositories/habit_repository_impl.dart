import 'dart:async';

import 'package:daybook/core/error/error_mapper.dart';
import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/core/storage/outbox.dart';
import 'package:daybook/core/sync/sync_engine.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/habits/data/datasources/habit_local_data_source.dart';
import 'package:daybook/features/habits/data/models/habit_model.dart';
import 'package:daybook/features/habits/domain/entities/habit.dart';
import 'package:daybook/features/habits/domain/repositories/habit_repository.dart';

/// Local-first, like tasks and events: writes go to SQLite plus the outbox,
/// and the [SyncEngine] delivers them.
class HabitRepositoryImpl implements HabitRepository {
  HabitRepositoryImpl({
    required this._db,
    required this._local,
    required this._outbox,
    required this._sync,
  });

  final AppDatabase _db;
  final HabitLocalDataSource _local;
  final Outbox _outbox;
  final SyncEngine _sync;

  @override
  Stream<List<Habit>> watchHabits() => _local.watchAll();

  @override
  Future<Result<void>> save(Habit habit) => _guard(() async {
    await _db.transaction(() async {
      final exists = await _local.getById(habit.id) != null;
      await _local.upsert(habit);
      await _outbox.add(
        entityType: 'habit',
        entityId: habit.id,
        operation: exists ? 'update' : 'create',
        payload: HabitModel.fromEntity(habit).toJson(),
      );
    });
    unawaited(_sync.syncNow());
  });

  @override
  Future<Result<void>> delete(String id) => _guard(() async {
    await _db.transaction(() async {
      await _local.delete(id);
      await _outbox.add(entityType: 'habit', entityId: id, operation: 'delete');
    });
    unawaited(_sync.syncNow());
  });

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
