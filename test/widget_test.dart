import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daybook/app.dart';
import 'package:daybook/core/di/injection.dart';
import 'package:daybook/core/storage/app_database.dart';

void main() {
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await configureDependencies();
    // The Dashboard reads the database: use one in memory, not on disk.
    getIt
      ..unregister<AppDatabase>()
      ..registerLazySingleton<AppDatabase>(
        () => AppDatabase(NativeDatabase.memory()),
        dispose: (db) => db.close(),
      );
  });
  tearDown(() => getIt.reset());

  testWidgets('no session -> login -> dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // No stored session, so the redirect leaves splash for login.
    // Login page is shown; sign in with the demo account.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'demo@daybook.dev',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    // Dashboard is shown inside the app shell. The default 800x600 test
    // surface is above the compact breakpoint, so the rail is used.
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);

    // Let the Dashboard's last requests finish before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
