import 'package:bloc_test/bloc_test.dart';
import 'package:daybook/core/routing/app_router.dart';
import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_event.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:daybook/features/settings/presentation/pages/gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  testWidgets('More page opens the widget gallery in debug mode', (
    tester,
  ) async {
    final auth = MockAuthBloc();
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const Authenticated(
        User(id: '1', email: 'a@b.c', name: 'A'),
      ),
    );
    final router = createAppRouter(auth)..go(Routes.more);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Widget gallery'));
    // The gallery shows a looping spinner, so pumpAndSettle would never settle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GalleryPage), findsOneWidget);
    expect(find.text('AppButton'), findsOneWidget);
  });
}
