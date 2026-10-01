import 'package:daybook/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  group('AppButton', () {
    testWidgets('shows label and calls onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpApp(AppButton(label: 'Save', onPressed: () => taps++));

      await tester.tap(find.text('Save'));

      expect(taps, 1);
    });

    testWidgets('renders the widget matching each variant', (tester) async {
      for (final (variant, type) in [
        (AppButtonVariant.primary, FilledButton),
        (AppButtonVariant.secondary, OutlinedButton),
        (AppButtonVariant.text, TextButton),
      ]) {
        await tester.pumpApp(
          AppButton(label: 'Go', variant: variant, onPressed: () {}),
        );
        expect(find.byType(type), findsOneWidget, reason: variant.name);
      }
    });

    testWidgets('shows icon when provided', (tester) async {
      await tester.pumpApp(
        AppButton(label: 'Add', icon: Icons.add, onPressed: () {}),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('loading shows spinner, hides label and ignores taps', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpApp(
        AppButton(label: 'Save', isLoading: true, onPressed: () => taps++),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);

      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });

    testWidgets('expand fills the available width', (tester) async {
      await tester.pumpApp(
        AppButton(label: 'Wide', expand: true, onPressed: () {}),
      );

      expect(
        tester.getSize(find.byType(FilledButton)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
    });
  });
}
