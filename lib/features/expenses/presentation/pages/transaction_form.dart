import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/core/utils/id.dart';
import 'package:daybook/features/expenses/domain/entities/transaction.dart';
import 'package:daybook/features/expenses/domain/entities/transaction_type.dart';
import 'package:daybook/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:daybook/features/expenses/presentation/widgets/category_icon.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/models/money.dart';
import 'package:daybook/shared/widgets/app_button.dart';
import 'package:daybook/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Log income or spending.
class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({super.key});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late final _state = context.read<ExpensesCubit>().state;

  TransactionType _type = TransactionType.expense;
  String? _categoryId;
  late String? _accountId = _state.accountId ?? _state.accounts.firstOrNull?.id;
  DateTime _date = DateTime.now();
  bool _showCategoryError = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 2),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    setState(() => _showCategoryError = _categoryId == null);
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    final now = DateTime.now();
    context.read<ExpensesCubit>().saveTransaction(
      Transaction(
        id: newId(),
        accountId: _accountId!,
        categoryId: _categoryId!,
        amount: Money.parse(_amount.text),
        type: _type,
        // Noon, so a time zone change can't move it to another day.
        date: DateTime(_date.year, _date.month, _date.day, 12),
        note: _note.text.trim(),
        createdAt: now,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      for (final c in _state.categories)
        if (c.type == _type) c,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Add transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.page,
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Spent'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Received'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null; // categories differ by type
              }),
            ),
            AppSpacing.gapLg,
            AppTextField(
              label: 'Amount (EGP)',
              hint: '0.00',
              controller: _amount,
              prefixIcon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final money = Money.tryParse(v ?? '');
                if (money == null) return 'Enter an amount like 12.50';
                if (money.isZero) return 'Must be more than zero';
                return null;
              },
            ),
            AppSpacing.gapLg,
            Text('Category', style: context.text.titleSmall),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    avatar: Icon(categoryIcon(c), color: Color(c.colorValue)),
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() {
                      _categoryId = c.id;
                      _showCategoryError = false;
                    }),
                  ),
              ],
            ),
            if (_showCategoryError)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Pick a category',
                  style: TextStyle(color: context.colors.error),
                ),
              ),
            AppSpacing.gapLg,
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(
                labelText: 'Account',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: [
                for (final a in _state.accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              validator: (v) => v == null ? 'Pick an account' : null,
              onChanged: (v) => setState(() => _accountId = v),
            ),
            AppSpacing.gapSm,
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                MaterialLocalizations.of(context).formatFullDate(_date),
              ),
              onTap: _pickDate,
            ),
            AppTextField(label: 'Note (optional)', controller: _note),
            AppSpacing.gapLg,
            AppButton(label: 'Save', expand: true, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
