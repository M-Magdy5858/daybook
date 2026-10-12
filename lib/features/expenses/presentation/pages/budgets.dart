import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/expenses/domain/entities/expense_category.dart';
import 'package:daybook/features/expenses/domain/entities/transaction_type.dart';
import 'package:daybook/features/expenses/domain/services/expense_summary.dart';
import 'package:daybook/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:daybook/features/expenses/presentation/cubit/expenses_state.dart';
import 'package:daybook/features/expenses/presentation/widgets/budget_bar.dart';
import 'package:daybook/features/expenses/presentation/widgets/category_icon.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Monthly limits per spending category, with how much of each is used.
class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  Future<void> _edit(BuildContext context, ExpenseCategory category) async {
    final result = await showDialog<(Money?,)>(
      context: context,
      builder: (_) => _BudgetDialog(category: category),
    );
    if (result != null && context.mounted) {
      await context.read<ExpensesCubit>().setBudget(category, result.$1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: BlocBuilder<ExpensesCubit, ExpensesState>(
        builder: (context, state) {
          final spent = ExpenseSummary.byCategory(
            ExpenseSummary.inMonth(
              state.transactions,
              state.month,
            ).where((t) => t.isExpense),
          );
          final use = state.budgetUse;
          final l = MaterialLocalizations.of(context);
          return ListView(
            padding: AppSpacing.page,
            children: [
              Text(
                'Spending in ${l.formatMonthYear(state.month)}. '
                'Tap a category to set its monthly limit.',
                style: context.text.bodyMedium,
              ),
              AppSpacing.gapMd,
              for (final c in state.categories)
                if (c.type == TransactionType.expense)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CategoryAvatar(category: c),
                    title: Text(c.name),
                    subtitle: switch (c.monthlyBudget) {
                      null => Text(
                        'No budget · spent '
                        '${context.formatMoney(spent[c.id] ?? Money.zero)}',
                      ),
                      final budget => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${context.formatMoney(spent[c.id] ?? Money.zero)}'
                            ' of ${context.formatMoney(budget)}',
                            style: TextStyle(
                              color: budgetColor(context, use[c.id] ?? 0),
                            ),
                          ),
                          AppSpacing.gapXs,
                          BudgetBar(use: use[c.id] ?? 0),
                        ],
                      ),
                    },
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _edit(context, c),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Its own widget so it owns the text controller: disposing it right after
/// `showDialog` returns would break the dialog's closing animation, which
/// still draws the field.
class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.category});

  final ExpenseCategory category;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final _controller = TextEditingController(
    text: widget.category.monthlyBudget?.toInputText() ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    final money = Money.tryParse(text);
    if (text.isNotEmpty && money == null) {
      setState(() => _error = 'Enter an amount like 1500');
      return;
    }
    Navigator.pop(context, (money,)); // empty text removes the budget
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.category.name} budget'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSubmitted: (_) => _save(),
      decoration: InputDecoration(
        labelText: 'Per month (EGP)',
        helperText: 'Leave empty for no budget',
        errorText: _error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
