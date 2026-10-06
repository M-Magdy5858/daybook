import 'package:daybook/core/error/failures.dart';
import 'package:daybook/core/routing/app_router.dart';
import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const authed = Authenticated(User(id: '1', email: 'a@b.c', name: 'A'));

  test('initial: anywhere -> splash, splash stays', () {
    expect(authRedirect(const AuthInitial(), Routes.tasks), Routes.splash);
    expect(authRedirect(const AuthInitial(), Routes.splash), isNull);
  });

  test('authenticated: splash/login -> dashboard, app pages stay', () {
    expect(authRedirect(authed, Routes.splash), Routes.dashboard);
    expect(authRedirect(authed, Routes.login), Routes.dashboard);
    expect(authRedirect(authed, Routes.tasks), isNull);
  });

  test('logged out: app pages -> login, auth pages stay', () {
    expect(authRedirect(const Unauthenticated(), Routes.tasks), Routes.login);
    expect(authRedirect(const Unauthenticated(), Routes.splash), Routes.login);
    expect(authRedirect(const Unauthenticated(), Routes.register), isNull);
    expect(
      authRedirect(const AuthFailure(UnauthorizedFailure()), Routes.login),
      isNull,
    );
  });
}
