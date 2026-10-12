import 'dart:async';
import 'dart:convert';

import 'package:daybook/core/error/error_mapper.dart';
import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/network/api_client.dart';
import 'package:daybook/core/network/connectivity_service.dart';
import 'package:daybook/core/storage/app_database.dart';
import 'package:daybook/core/storage/outbox.dart';
import 'package:daybook/core/sync/sync_store.dart';
import 'package:daybook/core/utils/result.dart';

/// Delivers the outbox to the server in order, then pulls server changes for
/// every [SyncStore]. On a network or server error it stops and retries with
/// exponential backoff. Conflicts (409) are settled by last-write-wins.
class SyncEngine {
  SyncEngine({
    required this._outbox,
    required this._api,
    required List<SyncStore> stores,
    required this._connectivity,
  }) : _stores = {for (final s in stores) s.entityType: s};

  final Outbox _outbox;
  final ApiClient _api;
  final Map<String, SyncStore> _stores;
  final ConnectivityService _connectivity;

  static const pageSize = 20;
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

  /// Fetch the latest server copies of just these kinds of item (e.g.
  /// `{'task'}`), without pushing. One failing collection doesn't touch the
  /// others, so a screen can refresh each of its sections on its own.
  Future<Result<void>> pull(Set<String> entityTypes) async {
    try {
      for (final type in entityTypes) {
        final store = _stores[type];
        if (store != null) await _pullStore(store);
      }
      return const Success(null);
    } catch (e) {
      return Err(ErrorMapper.toFailure(e));
    }
  }

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
      final store = _stores[m.entityType];
      if (store != null) {
        try {
          await _send(store, m);
        } on ConflictException catch (c) {
          final server = c.serverData?['item'];
          if (server is Map<String, dynamic>) {
            await _resolve(store, m, server);
          }
        } on AppException catch (e) {
          if (_isTemporary(e)) {
            await _outbox.markAttempt(m.id);
            rethrow; // stop here: later changes may depend on this one
          }
          // Rejected for good (404, 422, ...): retrying won't help.
        }
      }
      await _outbox.remove(m.id);
    }
  }

  Future<void> _send(SyncStore store, PendingMutation m) async {
    final payload = jsonDecode(m.payloadJson) as Map<String, dynamic>;
    final itemPath = '${store.path}/${m.entityId}';
    switch (m.operation) {
      case 'delete':
        await _api.delete(itemPath);
      case 'create':
        final saved = await _api.post(store.path, body: payload);
        await store.setVersion(m.entityId, saved['version'] as int);
      case 'update':
        // Base the change on the version we hold now: an earlier change in
        // this same run may have bumped it.
        final version = await store.versionOf(m.entityId) ?? payload['version'];
        final saved = await _api.patch(
          itemPath,
          body: {...payload, 'version': version},
        );
        await store.setVersion(m.entityId, saved['version'] as int);
    }
  }

  /// Last-write-wins: keep whichever copy was edited more recently.
  Future<void> _resolve(
    SyncStore store,
    PendingMutation m,
    Map<String, dynamic> server,
  ) async {
    final mine = jsonDecode(m.payloadJson) as Map<String, dynamic>;
    if (_updatedAt(server).isAfter(_updatedAt(mine))) {
      await store.upsertJson([server]); // the server wins
      return;
    }
    // Ours wins: send it again, now based on the server's version.
    final saved = await _api.patch(
      '${store.path}/${m.entityId}',
      body: {...mine, 'version': server['version']},
    );
    await store.setVersion(m.entityId, saved['version'] as int);
  }

  Future<void> _pull() async {
    final startedAt = DateTime.now();
    for (final store in _stores.values) {
      await _pullStore(store);
    }
    _lastPull = startedAt;
  }

  Future<void> _pullStore(SyncStore store) async {
    final pending = await _outbox.pendingIds(store.entityType);
    final local = await store.syncInfo();
    final since = _lastPull;

    for (var page = 1; ; page++) {
      final res = await _api.get(
        store.path,
        query: {
          'page': page,
          'limit': pageSize,
          if (since != null) 'updatedSince': since.toUtc().toIso8601String(),
        },
      );
      final newer = <Map<String, dynamic>>[];
      for (final item in (res['items'] as List).cast<Map<String, dynamic>>()) {
        final id = item['id'] as String;
        if (pending.contains(id)) continue; // our change goes first
        final mine = local[id];
        if (mine == null || _updatedAt(item).isAfter(mine.updatedAt)) {
          newer.add(item);
        } else if ((item['version'] as int) > mine.version) {
          await store.setVersion(id, item['version'] as int);
        }
      }
      await store.upsertJson(newer);
      if (page * pageSize >= (res['total'] as int)) break;
    }
  }

  static DateTime _updatedAt(Map<String, dynamic> json) =>
      DateTime.parse(json['updatedAt'] as String);

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
