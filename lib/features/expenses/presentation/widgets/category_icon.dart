import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:flutter/material.dart';

/// Categories store their icon as a number. Building `IconData(code)` at run
/// time would stop Flutter from shrinking the icon font in release builds
/// (the build fails), so known codes map to constant icons instead.
const _icons = <int, IconData>{
  0xe532: Icons.restaurant,
  0xe1d5: Icons.directions_bus,
  0xe59a: Icons.shopping_bag,
  0xe50d: Icons.receipt_long,
  0xe40d: Icons.movie,
  0xe396: Icons.local_hospital,
  0xe482: Icons.payments,
  0xe13e: Icons.card_giftcard,
};

IconData categoryIcon(ExpenseCategory? c) =>
    _icons[c?.iconCode] ?? Icons.category_outlined;

/// The category's icon on a soft circle in its color.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.radius = 20});

  final ExpenseCategory? category;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Color(category?.colorValue ?? 0xFF9E9E9E);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.18),
      child: Icon(categoryIcon(category), color: color, size: radius),
    );
  }
}
