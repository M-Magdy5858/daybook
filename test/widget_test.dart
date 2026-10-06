import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daybook/app.dart';
import 'package:daybook/core/di/injection.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    return configureDependencies();
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
    expect(find.text('dashboard'), findsWidgets);
  });
}
