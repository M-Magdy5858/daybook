import 'dart:async';
import 'dart:convert';

import 'package:daybook/core/error/error_mapper.dart';
import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/network/connectivity_service.dart';
import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/core/storage/outbox.dart';
import 'package:daybook/core/utils/result.dart';
import 'package:daybook/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:daybook/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:daybook/features/tasks/data/models/task_model.dart';
import 'package:daybook/features/tasks/data/sync/conflict_resolver.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';

/// Delivers the outbox to the server in order, then pulls server changes.
/// On a network or server error it stops and retries with exponential backoff.
class SyncEngine {
  SyncEngine({
    required this._outbox,
    required this._local,
    required this._remote,
    required this._resolver,
    required this._connectivity,
  });

  final Outbox _outbox;
  final TaskLocalDataSource _local;
  final TaskRemoteDataSource _remote;
  final ConflictResolver _resolver;
  final ConnectivityService _connectivity;

  static const _minDelay = Duration(seconds: 1);
  static const _maxDelay = Duration(seconds: 60);

  Duration _delay = _minDelay;
  Timer? _retryTimer;
  Timer? _periodic;
  StreamSubscription<bool>? _onlineSub;
  Future<Result<void>>? _running;
  DateTime? _lastPull;

  /// Start syncing: now, whenever the device comes online, and every 30 s.
  void start() {
    stop();
    _onlineSub = _connectivity.onlineChanges.listen((online) {
      if (online) syncNow();
    });
    _periodic = Timer.periodic(const Duration(seconds: 30), (_) => syncNow());
    syncNow();
  }

  /// Stop all timers and listeners (on logout).
  void stop() {
    _retryTimer?.cancel();
    _periodic?.cancel();
    _onlineSub?.cancel();
    _retryTimer = _periodic = _onlineSub = null;
    _delay = _minDelay;
    _lastPull = null;
  }

  /// Push then pull. Never runs twice at once: a second call gets the run
  /// that's already in progress.
  Future<Result<void>> syncNow() =>
      _running ??= _run().whenComplete(() => _running = null);

  Future<Result<void>> _run() async {
    try {
      await _push();
      await _pull();
      _delay = _minDelay; // reset after success
      return const Success(null);
    } on AppException catch (e) {
      _scheduleRetry();
      return Err(ErrorMapper.toFailure(e));
    } catch (e) {
      return Err(ErrorMapper.toFailure(e));
    }
  }

  Future<void> _push() async {
    for (final m in await _outbox.oldestFirst()) {
      try {
        await _send(m);
      } on ConflictException catch (c) {
        final serverTask = c.serverData?['task'];
        if (serverTask is Map<String, dynamic>) {
          await _resolver.resolve(local: m, serverTask: serverTask);
        }
      } on AppException catch (e) {
        if (_isTemporary(e)) {
          await _outbox.markAttempt(m.id);
          rethrow; // stop here: later changes may depend on this one
        }
        // Rejected for good (404, 422, ...): retrying won't help.
      }
      await _outbox.remove(m.id);
    }
  }

  Future<void> _send(PendingMutation m) async {
    final payload = jsonDecode(m.payloadJson) as Map<String, dynamic>;
    switch (m.operation) {
      case 'delete':
        await _remote.delete(m.entityId);
      case 'create':
        final saved = await _remote.create(TaskModel.fromJson(payload));
        await _local.setVersion(saved.id, saved.version);
      case 'update':
        // Base the change on the version we hold now: an earlier change in
        // this same run may have bumped it.
        final current = await _local.getById(m.entityId);
        final version = current?.version ?? payload['version'];
        final saved = await _remote.update(
          TaskModel.fromJson({...payload, 'version': version}),
        );
        await _local.setVersion(saved.id, saved.version);
    }
  }

  Future<void> _pull() async {
    final startedAt = DateTime.now();
    final pending = await _outbox.pendingIds('task');
    final local = {for (final t in await _local.getAll()) t.id: t};

    var page = 1;
    while (true) {
      final res = await _remote.fetchPage(page, updatedSince: _lastPull);
      final newer = <Task>[];
      for (final model in res.items) {
        if (pending.contains(model.id)) continue; // our change goes first
        final server = model.toEntity();
        final mine = local[server.id];
        if (mine == null || server.updatedAt.isAfter(mine.updatedAt)) {
          newer.add(server);
        } else if (server.version > mine.version) {
          await _local.setVersion(server.id, server.version);
        }
      }
      await _local.upsertAll(newer);
      if (page * TaskRemoteDataSource.pageSize >= res.total) break;
      page++;
    }
    _lastPull = startedAt;
  }

  bool _isTemporary(AppException e) => switch (e) {
    NetworkException() ||
    RequestTimeoutException() ||
    ServerException() ||
    AuthenticationException() => true,
    _ => false,
  };

  void _scheduleRetry() {
    if (_onlineSub == null) return; // not started (e.g. logged out)
    _retryTimer?.cancel();
    _retryTimer = Timer(_delay, syncNow);
    final doubled = _delay * 2;
    _delay = doubled > _maxDelay ? _maxDelay : doubled;
  }
}
