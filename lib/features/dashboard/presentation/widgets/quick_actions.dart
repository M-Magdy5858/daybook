import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shortcuts to the forms other tabs already have.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static const _actions = [
    (Icons.add_task, 'New task', Routes.taskNew),
    (Icons.event, 'Add event', Routes.eventNew),
    (Icons.receipt_long, 'Log expense', Routes.expenseNew),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final (icon, label, route) in _actions)
        // `go`, not `push`: these forms live in other tabs, so this switches
        // to that tab with the form on top.
        ActionChip(
          avatar: Icon(icon),
          label: Text(label),
          onPressed: () => context.go(route),
        ),
    ],
  );
}
