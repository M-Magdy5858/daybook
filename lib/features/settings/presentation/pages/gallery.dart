import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Debug-only showcase of the shared widgets in `lib/shared/widgets`.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widget Gallery')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          _Section(
            title: 'AppButton',
            children: [
              for (final variant in AppButtonVariant.values) ...[
                AppButton(
                  label: variant.name,
                  variant: variant,
                  onPressed: () => context.showSnack('${variant.name} tapped'),
                ),
                AppSpacing.gapSm,
              ],
              AppButton(
                label: 'With icon',
                icon: Icons.add,
                onPressed: () => context.showSnack('icon tapped'),
              ),
              AppSpacing.gapSm,
              const AppButton(label: 'Loading', isLoading: true, onPressed: null),
              AppSpacing.gapSm,
              const AppButton(label: 'Disabled', onPressed: null),
              AppSpacing.gapSm,
              AppButton(
                label: 'Expanded',
                expand: true,
                onPressed: () => context.showSnack('expanded tapped'),
              ),
            ],
          ),
          const _Section(
            title: 'AppTextField',
            children: [
              AppTextField(label: 'Email', hint: 'you@example.com', prefixIcon: Icons.email_outlined),
              AppSpacing.gapMd,
              AppTextField(label: 'Password', obscureText: true, prefixIcon: Icons.lock_outline),
              AppSpacing.gapMd,
              AppTextField(label: 'With error', errorText: 'This field is required'),
              AppSpacing.gapMd,
              AppTextField(label: 'Notes', maxLines: 3),
            ],
          ),
          _Section(
            title: 'AppCard',
            children: [
              const AppCard(child: Text('Static card')),
              AppCard(
                onTap: () => context.showSnack('card tapped'),
                child: const Text('Tappable card'),
              ),
            ],
          ),
          const _Section(
            title: 'AppLoadingState',
            children: [SizedBox(height: 80, child: AppLoadingState())],
          ),
          _Section(
            title: 'AppEmptyState',
            children: [
              AppEmptyState(
                title: 'No tasks yet',
                message: 'Tasks you add will show up here.',
                action: AppButton(
                  label: 'Add task',
                  onPressed: () => context.showSnack('add tapped'),
                ),
              ),
            ],
          ),
          _Section(
            title: 'AppErrorState',
            children: [
              AppErrorState(
                message: 'Something went wrong.',
                onRetry: () => context.showSnack('retry tapped'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleMedium),
          AppSpacing.gapSm,
          ...children,
        ],
      ),
    );
  }
}
