import 'package:daybook/core/di/injection.dart';
import 'package:daybook/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.light,      
      darkTheme: AppTheme.dark,
      routerConfig: getIt<GoRouter>(),
    );
  }
}
