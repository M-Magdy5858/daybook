import 'package:daybook/core/di/injection.dart';
import 'package:daybook/core/notifications/notification_service.dart';
import 'package:daybook/core/theme/app_theme.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Forms ask for notification permission at the right moment.
        RepositoryProvider<NotificationService>.value(
          value: getIt<NotificationService>(),
        ),
      ],
      child: BlocProvider.value(
        value: getIt<AuthBloc>(),
        child: MaterialApp.router(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: getIt<GoRouter>(),
        ),
      ),
    );
  }
}
