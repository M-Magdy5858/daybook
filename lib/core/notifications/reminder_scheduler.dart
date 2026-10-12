import 'dart:async';

import 'package:daybook/core/notifications/notification_service.dart';
import 'package:daybook/core/notifications/reminder.dart';
import 'package:flutter/foundation.dart';

/// Keeps scheduled notifications in step with the app's data. Each source
/// emits the full list of reminders one feature wants (tasks, events…);
/// whenever any of them changes, new reminders are scheduled, changed ones
/// rescheduled and stale ones cancelled.
class ReminderScheduler {
  ReminderScheduler(this._notifications, {required this._sources});

  static const maxScheduled = 50;

  final NotificationService _notifications;
  final List<Stream<List<Reminder>> Function()> _sources;

  final _subs = <StreamSubscription<List<Reminder>>>[];
  late List<List<Reminder>> _latest;

  /// What we've scheduled, by notification id.
  final _scheduled = <int, Reminder>{};

  /// Ids scheduled in an earlier run whose details we don't know.
  Set<int> _leftovers = {};
  Future<void> _queue = Future.value();

  Future<void> start() async {
    await stop(cancelAll: false);
    _leftovers = await _notifications.pendingIds();
    _latest = List.filled(_sources.length, const []);
    for (final (i, source) in _sources.indexed) {
      _subs.add(
        source().listen((reminders) {
          _latest[i] = reminders;
          _enqueue(_sync);
        }),
      );
    }
  }

  /// Recheck everything, e.g. when the app returns to the foreground after a
  /// repeating event's reminder has fired and the next one is due.
  void rescan() {
    if (_subs.isNotEmpty) _enqueue(_sync);
  }

  /// Stop listening. On logout, [cancelAll] removes every reminder so the
  /// next user doesn't get them.
  Future<void> stop({bool cancelAll = true}) async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    if (cancelAll) {
      final ids = {..._scheduled.keys, ...await _notifications.pendingIds()};
      for (final id in ids) {
        await _notifications.cancel(id);
      }
    }
    _scheduled.clear();
  }

  /// Runs syncs one after another, so two never interleave.
  void _enqueue(Future<void> Function() job) {
    _queue = _queue.then((_) => job()).catchError((Object e) {
      debugPrint('Reminder sync failed: $e');
    });
  }

  Future<void> _sync() async {
    final now = DateTime.now();
    // iOS keeps at most 64 pending notifications, so only the soonest few
    // are scheduled; later ones get their turn on a later sync.
    final soonest = [
      for (final r in _latest.expand((list) => list))
        if (r.when.isAfter(now)) r,
    ]..sort((a, b) => a.when.compareTo(b.when));
    final wanted = {
      for (final r in soonest.take(maxScheduled)) r.notificationId: r,
    };

    for (final MapEntry(key: id, value: reminder) in wanted.entries) {
      if (_scheduled[id] != reminder) {
        await _notifications.schedule(reminder); // same id replaces
        _scheduled[id] = reminder;
      }
    }
    final stale = {..._scheduled.keys, ..._leftovers}..removeAll(wanted.keys);
    for (final id in stale) {
      await _notifications.cancel(id);
      _scheduled.remove(id);
    }
    _leftovers = {};
  }
}
