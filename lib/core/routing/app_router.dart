import 'package:daybook/core/di/injection.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:daybook/core/network/mock/mock_settings.dart';
import 'package:daybook/core/routing/app_shell.dart';
import 'package:daybook/core/routing/deep_link_parser.dart';
import 'package:daybook/core/routing/go_router_refresh_stream.dart';
import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_state.dart';
import 'package:daybook/features/auth/presentation/pages/login.dart';
import 'package:daybook/features/auth/presentation/pages/register.dart';
import 'package:daybook/features/auth/presentation/pages/splash.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:daybook/features/calendar/presentation/pages/calendar.dart';
import 'package:daybook/features/calendar/presentation/pages/event_form.dart';
import 'package:daybook/features/dashboard/presentation/pages/dashboard.dart';
import 'package:daybook/features/habits/presentation/cubit/habits_cubit.dart';
import 'package:daybook/features/habits/presentation/pages/habit_details.dart';
import 'package:daybook/features/habits/presentation/pages/habit_form.dart';
import 'package:daybook/features/habits/presentation/pages/habits.dart';
import 'package:daybook/features/settings/presentation/pages/dev_tools.dart';
import 'package:daybook/features/settings/presentation/pages/gallery.dart';
import 'package:daybook/features/settings/presentation/pages/more.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:daybook/features/tasks/presentation/pages/task_details.dart';
import 'package:daybook/features/tasks/presentation/pages/task_form.dart';
import 'package:daybook/features/tasks/presentation/pages/tasks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// [authRedirect] plus deep links: `daybook://` links become app routes, and
/// a link opened before the session check finishes, or while logged out, is
/// remembered and opened right after login.
class AppRedirect {
  String? _pending;

  String? call(AuthState auth, Uri uri, String matchedLocation) {
    final link = DeepLinks.parse(uri);
    final location = link ?? matchedLocation;
    final target = authRedirect(auth, location);
    final isAppPage =
        location != Routes.splash && !Routes.authRoutes.contains(location);

    // Remember where the user was headed, but only for links and app start:
    // after a normal logout, the next login should land on the dashboard.
    if (target != null && isAppPage && (link != null || auth is AuthInitial)) {
      _pending = link ?? uri.toString();
    }
    if (auth is Authenticated && target == Routes.dashboard) {
      final pending = _pending;
      _pending = null;
      return pending ?? target;
    }
    return target ?? link;
  }
}

GoRouter createAppRouter(AuthBloc auth) {
  final redirect = AppRedirect();
  return GoRouter(
    navigatorKey: rootNavigationKey,
    initialLocation: Routes.splash,
    refreshListenable: GoRouterRefreshStream(auth.stream),
    redirect: (_, state) =>
        redirect(auth.state, state.uri, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: Routes.scheduleTask,
        builder: (_, s) => BlocProvider(
          create: (_) => getIt<CalendarCubit>(),
          child: EventFormPage(
            taskId: s.uri.queryParameters['taskId'],
            taskTitle: s.uri.queryParameters['title'],
          ),
        ),
      ),

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
              // One TasksBloc for the list and every page pushed from it.
              ShellRoute(
                builder: (_, _, child) => BlocProvider(
                  create: (_) =>
                      getIt<TasksBloc>()..add(const TasksSubscribed()),
                  child: child,
                ),
                routes: [
                  GoRoute(
                    path: Routes.tasks,
                    builder: (_, _) => const TasksPage(),
                    routes: [
                      // 'new' must come before ':id', or "new" would be an id.
                      GoRoute(
                        path: 'new',
                        builder: (_, _) => const TaskFormPage(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (_, s) =>
                            TaskDetailsPage(id: s.pathParameters['id']!),
                        routes: [
                          GoRoute(
                            path: 'edit',
                            builder: (_, s) =>
                                TaskFormPage(id: s.pathParameters['id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              ShellRoute(
                builder: (_, _, child) => BlocProvider(
                  create: (_) => getIt<CalendarCubit>()..load(),
                  child: child,
                ),
                routes: [
                  GoRoute(
                    path: Routes.calendar,
                    builder: (_, _) => const CalendarPage(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (_, s) => EventFormPage(
                          initialDate: DateTime.tryParse(
                            s.uri.queryParameters['date'] ?? '',
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'events/:id',
                        builder: (_, s) =>
                            EventFormPage(id: s.pathParameters['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              ShellRoute(
                builder: (_, _, child) => BlocProvider(
                  create: (_) => getIt<HabitsCubit>()..load(),
                  child: child,
                ),
                routes: [
                  GoRoute(
                    path: Routes.habits,
                    builder: (_, _) => const HabitsPage(),
                    routes: [
                      // 'new' must come before ':id', or "new" would be an id.
                      GoRoute(
                        path: 'new',
                        builder: (_, _) => const HabitFormPage(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (_, s) =>
                            HabitDetailsPage(id: s.pathParameters['id']!),
                        routes: [
                          GoRoute(
                            path: 'edit',
                            builder: (_, s) =>
                                HabitFormPage(id: s.pathParameters['id']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
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
                      builder: (_, _) => DevToolsPage(
                        settings: getIt<MockSettings>(),
                        server: getIt<MockServerState>(),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
