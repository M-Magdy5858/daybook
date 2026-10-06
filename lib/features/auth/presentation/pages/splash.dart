import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/auth/presentation/widgets/auth_layout.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Shown while the stored session is checked; the router redirect moves on.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 88),
            const SizedBox(height: AppSpacing.lg),
            Text('Daybook', style: context.text.headlineMedium),
            const SizedBox(height: AppSpacing.xl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
