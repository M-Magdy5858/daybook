import 'package:daybook/core/routing/app_router.dart';
import 'package:daybook/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.light,      
      darkTheme: AppTheme.dark,
      // themeMode: ThemeMode.dark,
      routerConfig: createAppRouter(),
    );
  }
}
