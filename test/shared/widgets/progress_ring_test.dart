import 'package:daybook/shared/widgets/progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('builds and animates between 0, 0.5 and 1', (tester) async {
    for (final value in [0.0, 0.5, 1.0]) {
      await tester.pumpApp(ProgressRing(value: value, child: Text('$value')));
      await tester.pumpAndSettle();
      expect(find.text('$value'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
