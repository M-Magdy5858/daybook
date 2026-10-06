import 'package:daybook/core/di/injection.dart';
import 'package:daybook/core/network/mock/mock_settings.dart';
import 'package:daybook/core/routing/app_shell.dart';
import 'package:daybook/core/routing/go_router_refresh_stream.dart';
import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:daybook/features/auth/presentation/pages/login.dart';
import 'package:daybook/features/auth/presentation/pages/register.dart';
import 'package:daybook/features/auth/presentation/pages/splash.dart';
import 'package:daybook/features/calendar/presentation/pages/calendar.dart';
import 'package:daybook/features/dashboard/presentation/pages/dashboard.dart';
import 'package:daybook/features/habits/presentation/pages/habits.dart';
import 'package:daybook/features/settings/presentation/pages/dev_tools.dart';
import 'package:daybook/features/settings/presentation/pages/gallery.dart';
import 'package:daybook/features/settings/presentation/pages/more.dart';
import 'package:daybook/features/tasks/presentation/pages/tasks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final rootNavigationKey = GlobalKey<NavigatorState>();

/// Where to send the user for [location] given the auth state, or `null`
/// to stay. Pure, so it's easy to unit-test.
String? authRedirect(AuthState auth, String location) {
  final onAuthPage = Routes.authRoutes.contains(location);
  return switch (auth) {
    AuthInitial() || AuthLoading() when location == Routes.splash => null,
    AuthInitial() => Routes.splash,
    Authenticated() when onAuthPage || location == Routes.splash =>
      Routes.dashboard,
    Authenticated() => null,
    _ when !onAuthPage => Routes.login,
    _ => null,
  };
}

GoRouter createAppRouter(AuthBloc auth) => GoRouter(
  navigatorKey: rootNavigationKey,
  initialLocation: Routes.splash,
  refreshListenable: GoRouterRefreshStream(auth.stream),
  redirect: (_, state) => authRedirect(auth.state, state.matchedLocation),
  routes: [
    GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
    GoRoute(path: Routes.register, builder: (_, _) => const RegisterPage()),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.dashboard,
              builder: (_, _) => const DashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: Routes.tasks, builder: (_, _) => const TasksPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.calendar,
              builder: (_, _) => const CalendarPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: Routes.habits, builder: (_, _) => const HabitsPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.more,
              builder: (_, _) => const MorePage(),
              routes: [
                if (kDebugMode)
                  GoRoute(
                    path: 'gallery',
                    parentNavigatorKey: rootNavigationKey,
                    builder: (_, _) => const GalleryPage(),
                  ),
                if (kDebugMode)
                  GoRoute(
                    path: 'dev',
                    parentNavigatorKey: rootNavigationKey,
                    builder: (_, _) =>
                        DevToolsPage(settings: getIt<MockSettings>()),
                  ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
