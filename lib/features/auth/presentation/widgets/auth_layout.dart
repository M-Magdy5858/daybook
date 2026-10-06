import 'package:daybook/core/theme/app_radius.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// The Daybook mark: a book icon on a rounded tile.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.menu_book_rounded,
        size: size * 0.55,
        color: context.colors.onPrimaryContainer,
      ),
    );
  }
}

/// Shared frame for the login and register pages: logo, title and subtitle
/// above a centered column that never grows wider than a phone, so it also
/// looks right on tablets.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Shown under the form, e.g. a link to the other auth page.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo()),
                  AppSpacing.gapLg,
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.text.headlineMedium,
                  ),
                  AppSpacing.gapSm,
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Card(
                    elevation: 0,
                    color: context.colors.surfaceContainerLow,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.large,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                  if (footer != null) ...[AppSpacing.gapMd, footer!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Question? Action" on one line, e.g. "New here? Create an account".
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  final String question;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: TextStyle(color: context.colors.onSurfaceVariant),
        ),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}
