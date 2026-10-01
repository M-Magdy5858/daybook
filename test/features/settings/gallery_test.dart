import 'package:daybook/core/routing/app_router.dart';
import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/features/settings/presentation/pages/gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('More page opens the widget gallery in debug mode', (
    tester,
  ) async {
    final router = createAppRouter()..go(Routes.more);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Widget gallery'));
    // The gallery shows a looping spinner, so pumpAndSettle would never settle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GalleryPage), findsOneWidget);
    expect(find.text('AppButton'), findsOneWidget);
  });
}
