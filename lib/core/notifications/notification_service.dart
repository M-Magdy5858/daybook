import 'package:daybook/core/notifications/reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications: scheduled by the app on the phone, no server.
abstract interface class NotificationService {
  /// Call once at startup. [onTap] gets the tapped notification's deep link
  /// while the app is running (in the foreground or background).
  Future<void> init({required void Function(String link) onTap});

  /// The deep link of the notification that launched the app from closed,
  /// if any. Returns it only once.
  Future<String?> takeLaunchLink();

  /// Ask the user to allow notifications. Call at a moment that explains
  /// itself, e.g. right after they set a due time. Returns whether allowed.
  Future<bool> requestPermission();

  Future<void> schedule(Reminder reminder);
  Future<void> cancel(int id);

  /// Ids of notifications scheduled but not shown yet.
  Future<Set<int>> pendingIds();
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _launchLinkTaken = false;

  @override
  Future<void> init({required void Function(String link) onTap}) async {
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Unknown time zone, using UTC: $e'); // e.g. on a simulator
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Don't ask on launch; see requestPermission().
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final link = response.payload;
        if (link != null) onTap(link);
      },
    );
  }

  @override
  Future<String?> takeLaunchLink() async {
    if (_launchLinkTaken) return null; // consume it once
    _launchLinkTaken = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp != true) return null;
    return launch!.notificationResponse?.payload;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final allowed =
        await android?.requestNotificationsPermission() ??
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        await macos?.requestPermissions(alert: true, badge: true, sound: true);
    return allowed ?? false;
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    // Scheduling in the past throws.
    if (!reminder.when.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: reminder.notificationId,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          reminder.channel.name,
          reminder.channel.title,
          channelDescription: reminder.channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      ),
      // Inexact needs no special permission; a minute late is fine here.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.link,
      // Repeating reminders: the OS fires them again on its own.
      matchDateTimeComponents: switch (reminder.repeat) {
        ReminderRepeat.none => null,
        ReminderRepeat.daily => DateTimeComponents.time,
        ReminderRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
      },
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<Set<int>> pendingIds() async => {
    for (final r in await _plugin.pendingNotificationRequests()) r.id,
  };
}
