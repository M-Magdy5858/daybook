import 'package:daybook/core/routing/app_router.dart';
import 'package:daybook/core/routing/deep_link_parser.dart';
import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/features/auth/domain/entities/user.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DeepLinks.parse maps links to routes', () {
    expect(DeepLinks.parse(Uri.parse('daybook://task/123')), '/tasks/123');
    expect(
      DeepLinks.parse(Uri.parse('daybook://event/9')),
      '/calendar/events/9',
    );
    expect(DeepLinks.parse(Uri.parse('daybook://nope/1')), Routes.dashboard);
    expect(DeepLinks.parse(Uri.parse('daybook://task')), Routes.dashboard);
    expect(DeepLinks.parse(Uri.parse('/tasks/1')), isNull); // not a link
  });

  test('a link opened while logged out opens right after login', () {
    final redirect = AppRedirect();
    const authed = Authenticated(User(id: '1', email: 'a@b.c', name: 'A'));
    final link = Uri.parse('daybook://task/7');

    expect(redirect(const Unauthenticated(), link, '/7'), Routes.login);
    expect(redirect(authed, Uri.parse(Routes.login), Routes.login), '/tasks/7');
    // Used once: the next login goes to the dashboard as usual.
    expect(
      redirect(authed, Uri.parse(Routes.login), Routes.login),
      Routes.dashboard,
    );
  });
}
