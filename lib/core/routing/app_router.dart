import 'package:daybook/core/routing/app_shell.dart';
import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/features/auth/presentation/pages/login.dart';
import 'package:daybook/features/auth/presentation/pages/register.dart';
import 'package:daybook/features/auth/presentation/pages/splash.dart';
import 'package:daybook/features/calendar/presentation/pages/calendar.dart';
import 'package:daybook/features/dashboard/presentation/pages/dashboard.dart';
import 'package:daybook/features/habits/presentation/pages/habits.dart';
import 'package:daybook/features/settings/presentation/pages/more.dart';
import 'package:daybook/features/tasks/presentation/pages/tasks.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final rootNavigationKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() => GoRouter(
  initialLocation: Routes.splash,
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
            GoRoute(path: Routes.more, builder: (_, _) => const MorePage()),
          ],
        ),
      ],
    ),
  ],
);
