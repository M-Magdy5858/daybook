import 'package:daybook/shared/widgets/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  group('AppLoadingState', () {
    testWidgets('shows a spinner with a semantics label', (tester) async {
      await tester.pumpApp(const AppLoadingState(label: 'Fetching'));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Fetching'), findsOneWidget);
    });
  });

  group('AppEmptyState', () {
    testWidgets('shows title, message, icon and action', (tester) async {
      await tester.pumpApp(
        const AppEmptyState(
          title: 'Nothing here',
          message: 'Add something',
          icon: Icons.task_alt,
          action: Text('Action'),
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add something'), findsOneWidget);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('omits optional message and action', (tester) async {
      await tester.pumpApp(const AppEmptyState(title: 'Nothing here'));

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('AppErrorState', () {
    testWidgets('shows message and retry calls onRetry', (tester) async {
      var retries = 0;
      await tester.pumpApp(
        AppErrorState(message: 'Failed', onRetry: () => retries++),
      );

      expect(find.text('Failed'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('hides retry button without onRetry', (tester) async {
      await tester.pumpApp(const AppErrorState(message: 'Failed'));

      expect(find.text('Retry'), findsNothing);
    });
  });
}
