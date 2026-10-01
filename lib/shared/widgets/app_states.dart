import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Centered spinner for screens or sections that are loading.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.label = 'Loading'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

/// Placeholder shown when there is no content to display.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StateLayout(
      icon: icon,
      iconSize: 56,
      iconColor: theme.colorScheme.outline,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (message != null) ...[
          AppSpacing.gapSm,
          Text(message!, textAlign: TextAlign.center),
        ],
        if (action != null) ...[AppSpacing.gapMd, action!],
      ],
    );
  }
}

/// Error message with an optional retry button.
class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: Icons.error_outline,
      iconSize: 48,
      iconColor: Theme.of(context).colorScheme.error,
      children: [
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          AppSpacing.gapMd,
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ],
    );
  }
}

/// Shared layout for the empty and error states: a decorative icon above
/// centered content.
class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.children,
  });

  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
            AppSpacing.gapMd,
            ...children,
          ],
        ),
      ),
    );
  }
}
