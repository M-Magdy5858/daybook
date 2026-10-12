import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:daybook/features/expenses/presentation/cubit/expenses_state.dart';
import 'package:daybook/features/expenses/presentation/widgets/bar_chart.dart';
import 'package:daybook/features/expenses/presentation/widgets/budget_bar.dart';
import 'package:daybook/features/expenses/presentation/widgets/category_icon.dart';
import 'package:daybook/features/expenses/presentation/widgets/donut_chart.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:daybook/shared/widgets/app_card.dart';
import 'package:daybook/shared/widgets/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            tooltip: 'Budgets',
            icon: const Icon(Icons.savings_outlined),
            onPressed: () => context.push(Routes.expenseBudgets),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.expenseNew),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: BlocConsumer<ExpensesCubit, ExpensesState>(
        listenWhen: (prev, next) =>
            next.failure != null && prev.failure != next.failure,
        listener: (context, state) => context.showSnack(state.failure!.message),
        builder: (context, state) {
          if (state.status == ExpensesStatus.loading) {
            return const AppLoadingState();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              96, // room for the button
            ),
            children: [
              _MonthSwitcher(month: state.month),
              _AccountFilter(state: state),
              AppSpacing.gapSm,
              _Totals(state: state),
              ..._budgetWarnings(context, state),
              AppSpacing.gapMd,
              _SpendingDonut(state: state),
              AppSpacing.gapMd,
              _MonthsBars(state: state),
              AppSpacing.gapMd,
              ..._transactionsByDay(context, state),
            ],
          );
        },
      ),
    );
  }

  /// Categories at 80% of their budget or more, this month.
  List<Widget> _budgetWarnings(BuildContext context, ExpensesState state) {
    final warnings = [
      for (final MapEntry(key: id, value: use) in state.budgetUse.entries)
        if (use >= 0.8) (state.category(id), use),
    ];
    if (warnings.isEmpty) return const [];
    return [
      AppSpacing.gapMd,
      AppCard(
        onTap: () => context.push(Routes.expenseBudgets),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budgets to watch', style: context.text.titleSmall),
            for (final (category, use) in warnings) ...[
              AppSpacing.gapSm,
              Text(
                '${category?.name}: ${(use * 100).round()}% used'
                '${use >= 1 ? ' (over budget)' : ''}',
                style: TextStyle(color: budgetColor(context, use)),
              ),
              AppSpacing.gapXs,
              BudgetBar(use: use),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _transactionsByDay(BuildContext context, ExpensesState state) {
    final txs = state.visible;
    if (txs.isEmpty) {
      return const [
        AppEmptyState(
          title: 'Nothing this month',
          message: 'Tap Add to log income or spending.',
          icon: Icons.receipt_long_outlined,
        ),
      ];
    }
    final byDay = <DateTime, List<Transaction>>{};
    for (final t in txs) {
      (byDay[t.date.startOfDay] ??= []).add(t);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final l = MaterialLocalizations.of(context);
    return [
      Text('Transactions', style: context.text.titleMedium),
      for (final day in days) ...[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(
            l.formatFullDate(day),
            style: context.text.labelLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        for (final t in byDay[day]!)
          _TransactionTile(key: ValueKey(t.id), t: t),
      ],
    ];
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExpensesCubit>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous month',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => cubit.changeMonth(-1),
        ),
        SizedBox(
          width: 160,
          child: Text(
            MaterialLocalizations.of(context).formatMonthYear(month),
            textAlign: TextAlign.center,
            style: context.text.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          icon: const Icon(Icons.chevron_right),
          onPressed: () => cubit.changeMonth(1),
        ),
      ],
    );
  }
}

class _AccountFilter extends StatelessWidget {
  const _AccountFilter({required this.state});

  final ExpensesState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExpensesCubit>();
    return Wrap(
      spacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('All accounts'),
          selected: state.accountId == null,
          onSelected: (_) => cubit.changeAccount(null),
        ),
        for (final a in state.accounts)
          ChoiceChip(
            label: Text(a.name),
            selected: state.accountId == a.id,
            onSelected: (_) => cubit.changeAccount(a.id),
          ),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.state});

  final ExpensesState state;

  @override
  Widget build(BuildContext context) {
    final totals = state.totals;
    final left = totals.remaining;
    Widget cell(String label, Money value, Color? color) => Expanded(
      child: MergeSemantics(
        child: Column(
          children: [
            Text(label, style: context.text.labelMedium),
            FittedBox(
              child: Text(
                context.formatMoney(value),
                style: context.text.titleMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
    return AppCard(
      child: Row(
        children: [
          cell('Income', totals.income, Colors.green.shade700),
          cell('Spent', totals.expenses, context.colors.error),
          cell('Left', left, left.minor < 0 ? context.colors.error : null),
        ],
      ),
    );
  }
}

class _SpendingDonut extends StatelessWidget {
  const _SpendingDonut({required this.state});

  final ExpensesState state;

  @override
  Widget build(BuildContext context) {
    final byCategory = state.spendingByCategory;
    final total = state.totals.expenses;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending by category', style: context.text.titleMedium),
          AppSpacing.gapMd,
          Center(
            child: DonutChart(
              semanticsLabel:
                  'Spent ${context.formatMoney(total)} this month: '
                  '${byCategory.entries.map((e) => '${state.category(e.key)?.name} ${context.formatMoney(e.value)}').join(', ')}',
              slices: [
                for (final MapEntry(key: id, value: m) in byCategory.entries)
                  (
                    color: Color(state.category(id)?.colorValue ?? 0xFF9E9E9E),
                    value: m.minor.toDouble(),
                  ),
              ],
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Spent', style: context.text.labelMedium),
                  Text(
                    context.formatMoney(total),
                    style: context.text.titleSmall,
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapMd,
          if (byCategory.isEmpty)
            const Center(child: Text('No spending this month'))
          else
            for (final MapEntry(key: id, value: m) in byCategory.entries)
              _LegendRow(
                color: Color(state.category(id)?.colorValue ?? 0xFF9E9E9E),
                name: state.category(id)?.name ?? 'Other',
                amount: context.formatMoney(m),
                percent: (m.ratioOf(total) * 100).round(),
              ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.name,
    required this.amount,
    required this.percent,
  });

  final Color color;
  final String name;
  final String amount;
  final int percent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        AppSpacing.gapSm,
        Expanded(child: Text(name)),
        Text('$percent%  ', style: context.text.bodySmall),
        Text(amount),
      ],
    ),
  );
}

class _MonthsBars extends StatelessWidget {
  const _MonthsBars({required this.state});

  final ExpensesState state;

  @override
  Widget build(BuildContext context) {
    final l = MaterialLocalizations.of(context);
    final months = state.lastSixMonths;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 6 months', style: context.text.titleMedium),
          AppSpacing.gapMd,
          BarChart(
            semanticsLabel: [
              for (final (m, spent) in months)
                '${l.formatMonthYear(m)}: ${context.formatMoney(spent)}',
            ].join(', '),
            bars: [
              for (final (m, spent) in months)
                (
                  // The month's short name, e.g. "Oct".
                  label: l.formatMonthYear(m).split(' ').first.substring(0, 3),
                  value: spent.minor.toDouble(),
                  highlighted: m == state.month,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({super.key, required this.t});

  final Transaction t;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExpensesCubit>();
    final state = cubit.state;
    final category = state.category(t.categoryId);
    final account = state.account(t.accountId);
    final sign = t.isExpense ? '−' : '+';

    return Dismissible(
      key: ValueKey('dismiss-${t.id}'),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: context.colors.error,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Icon(Icons.delete, color: context.colors.onError),
          ),
        ),
      ),
      onDismissed: (_) {
        cubit.deleteTransaction(t.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Transaction deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => cubit.saveTransaction(t),
              ),
            ),
          );
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CategoryAvatar(category: category),
        title: Text(category?.name ?? 'Other'),
        subtitle: Text(
          [if (t.note.isNotEmpty) t.note, ?account?.name].join(' · '),
        ),
        trailing: Text(
          '$sign${context.formatMoney(t.amount)}',
          style: context.text.titleSmall?.copyWith(
            color: t.isExpense ? null : Colors.green.shade700,
          ),
        ),
      ),
    );
  }
}
