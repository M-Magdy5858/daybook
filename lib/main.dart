import 'package:daybook/app.dart';
import 'package:daybook/core/di/injection.dart';
import 'package:daybook/core/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();
  final router = getIt<GoRouter>();
  final notifications = getIt<NotificationService>();
  // A tap while the app is running: open the reminder's deep link.
  await notifications.init(onTap: router.go);
  startSessionServices();

  runApp(const MyApp());

  // A tap that launched the app from closed. The router remembers the link
  // while the session check (and maybe login) runs, then opens it.
  final launchLink = await notifications.takeLaunchLink();
  if (launchLink != null) router.go(launchLink);
}
