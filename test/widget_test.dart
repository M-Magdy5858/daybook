import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daybook/app.dart';

void main() {
  testWidgets('navigates from splash to login to dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Starts on the splash page.
    expect(find.text('go to login'), findsOneWidget);

    await tester.tap(find.text('go to login'));
    await tester.pumpAndSettle();

    // Login page is shown.
    expect(find.text('home'), findsOneWidget);

    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();

    // Dashboard is shown inside the app shell. The default 800x600 test
    // surface is above the compact breakpoint, so the rail is used.
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('dashboard'), findsWidgets);
  });
}
