import 'package:daybook/core/theme/app_colors.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Normal below 80%, the warning color from 80%, the error color at 100%.
Color budgetColor(BuildContext context, double use) => use >= 1
    ? context.colors.error
    : use >= 0.8
    ? AppColors.warning
    : context.colors.primary;

class BudgetBar extends StatelessWidget {
  const BudgetBar({super.key, required this.use});

  /// 0.8 is 80%; above 1.0 is over budget.
  final double use;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: LinearProgressIndicator(
      value: use.clamp(0, 1),
      minHeight: 8,
      color: budgetColor(context, use),
      backgroundColor: context.colors.surfaceContainerHighest,
    ),
  );
}
