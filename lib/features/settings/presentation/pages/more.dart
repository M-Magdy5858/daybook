import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Expenses'),
            subtitle: const Text('Spending, income and budgets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.expenses),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () => context.read<AuthBloc>().add(const LogoutRequested()),
          ),
          if (kDebugMode) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: const Text('Widget gallery'),
              onTap: () => context.go(Routes.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.developer_mode),
              title: const Text('Dev Tools'),
              onTap: () => context.go(Routes.devTools),
            ),
          ],
        ],
      ),
    );
  }
}
