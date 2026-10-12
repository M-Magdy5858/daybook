import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/models/section_state.dart';
import 'package:daybook/shared/widgets/app_card.dart';
import 'package:daybook/shared/widgets/app_states.dart';
import 'package:flutter/material.dart';

/// A titled card that shows any [SectionState]: a spinner, an empty
/// message, an error with Retry, or [builder]'s content.
class DashboardSection<T> extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    required this.state,
    required this.builder,
    required this.onRetry,
    this.emptyText,
    this.onSeeAll,
  });

  final String title;
  final SectionState<T> state;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;

  /// Shown when there's nothing; defaults to "Nothing here yet".
  final String? emptyText;

  /// Adds a "See all" button next to the title.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: context.text.titleMedium),
              ),
            ),
            if (onSeeAll != null)
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
          ],
        ),
        AppSpacing.gapMd,
        // Switching on a sealed class: the compiler checks all four are here.
        switch (state) {
          SectionLoading() => const SizedBox(
            height: 96,
            child: AppLoadingState(),
          ),
          SectionEmpty() => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              emptyText ?? 'Nothing here yet',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          SectionError(:final failure) => AppErrorState(
            message: failure.message,
            onRetry: onRetry,
          ),
          SectionData(:final data) => builder(data),
        },
      ],
    ),
  );
}
