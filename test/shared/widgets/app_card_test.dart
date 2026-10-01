import 'package:daybook/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  group('AppCard', () {
    testWidgets('renders its child inside a Card', (tester) async {
      await tester.pumpApp(const AppCard(child: Text('Content')));

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        AppCard(onTap: () => taps++, child: const Text('Tap me')),
      );

      await tester.tap(find.text('Tap me'));

      expect(taps, 1);
    });
  });
}
