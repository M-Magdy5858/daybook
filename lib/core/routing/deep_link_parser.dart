import 'package:daybook/core/routing/routes.dart';

/// `daybook://` links, used by the URL scheme and by notification taps.
abstract final class DeepLinks {
  static const scheme = 'daybook';

  static String task(String id) => '$scheme://task/$id';
  static String event(String id) => '$scheme://event/$id';

  /// The app route for [uri], or `null` if it isn't a `daybook://` link.
  /// Unknown or incomplete links go to the dashboard.
  ///
  /// `daybook://task/123` → `/tasks/123`,
  /// `daybook://event/9` → `/calendar/events/9`.
  static String? parse(Uri uri) {
    if (uri.scheme != scheme) return null;
    final id = uri.pathSegments.where((s) => s.isNotEmpty).firstOrNull;
    return switch ((uri.host, id)) {
      ('task', final String id) => Routes.taskDetail(id),
      ('event', final String id) => Routes.eventDetail(id),
      _ => Routes.dashboard,
    };
  }
}
