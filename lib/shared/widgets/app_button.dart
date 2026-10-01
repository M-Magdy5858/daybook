import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: onTap, child: child),
      AppButtonVariant.secondary => OutlinedButton(onPressed: onTap, child: child),
      AppButtonVariant.text => TextButton(onPressed: onTap, child: child),
    };

    final wrapped = Semantics(
      button: true,
      label: isLoading ? '$label, loading' : null,
      child: button,
    );

    return expand ? SizedBox(width: double.infinity, child: wrapped) : wrapped;
  }
}
