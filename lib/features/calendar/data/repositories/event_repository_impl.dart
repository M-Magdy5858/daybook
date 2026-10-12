import 'dart:async';

import 'package:daybook/core/error/error_mapper.dart';
import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/core/storage/outbox.dart';
import 'package:daybook/core/sync/sync_engine.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/calendar/data/datasources/event_local_data_source.dart';
import 'package:daybook/features/calendar/data/models/event_model.dart';
import 'package:daybook/features/calendar/domain/entities/event.dart';
import 'package:daybook/features/calendar/domain/repositories/event_repository.dart';

/// Local-first, like tasks: writes go to SQLite plus the outbox, and the
/// [SyncEngine] delivers them.
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl({
    required this._db,
    required this._local,
    required this._outbox,
    required this._sync,
  });

  final AppDatabase _db;
  final EventLocalDataSource _local;
  final Outbox _outbox;
  final SyncEngine _sync;

  @override
  Stream<List<Event>> watchEvents() => _local.watchAll();

  @override
  Future<Result<void>> save(Event event) => _guard(() async {
    await _db.transaction(() async {
      final exists = await _local.getById(event.id) != null;
      await _local.upsert(event);
      await _outbox.add(
        entityType: 'event',
        entityId: event.id,
        operation: exists ? 'update' : 'create',
        payload: EventModel.fromEntity(event).toJson(),
      );
    });
    unawaited(_sync.syncNow());
  });

  @override
  Future<Result<void>> delete(String id) => _guard(() async {
    await _db.transaction(() async {
      await _local.delete(id);
      await _outbox.add(entityType: 'event', entityId: id, operation: 'delete');
    });
    unawaited(_sync.syncNow());
  });

  @override
  Future<Result<void>> pull() => _sync.pull({'event'});

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
