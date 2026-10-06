import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:daybook/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('More Page'),
            TextButton.icon(
              onPressed: () =>
                  context.read<AuthBloc>().add(const LogoutRequested()),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
            if (kDebugMode) ...[
              TextButton.icon(
                onPressed: () => context.go(Routes.gallery),
                icon: const Icon(Icons.widgets_outlined),
                label: const Text('Widget gallery'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => context.go(Routes.devTools),
                icon: const Icon(Icons.developer_mode),
                label: const Text('Dev Tools'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
