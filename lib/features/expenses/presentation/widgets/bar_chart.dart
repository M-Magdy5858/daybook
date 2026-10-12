import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

typedef Bar = ({String label, double value, bool highlighted});

/// Vertical bars, one `drawRRect` each, scaled to the tallest. Labels are
/// ordinary widgets underneath, so they follow the text theme.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.bars,
    required this.semanticsLabel,
    this.height = 140,
  });

  final List<Bar> bars;
  final String semanticsLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarPainter(
                bars,
                normal: context.colors.primary.withValues(alpha: 0.35),
                highlight: context.colors.primary,
              ),
            ),
          ),
          AppSpacing.gapXs,
          Row(
            children: [
              for (final b in bars)
                Expanded(
                  child: Text(
                    b.label,
                    textAlign: TextAlign.center,
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: b.highlighted ? FontWeight.bold : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.bars, {required this.normal, required this.highlight});

  final List<Bar> bars;
  final Color normal;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final max = bars.map((b) => b.value).fold(0.0, (a, b) => a > b ? a : b);
    final slot = size.width / bars.length;
    final barWidth = slot * 0.5;
    for (final (i, b) in bars.indexed) {
      final h = max == 0 ? 0.0 : size.height * b.value / max;
      final left = slot * i + (slot - barWidth) / 2;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, size.height - h, barWidth, h),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        Paint()..color = b.highlighted ? highlight : normal,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.normal != normal ||
      old.highlight != highlight ||
      old.bars.length != bars.length ||
      [
        for (var i = 0; i < bars.length; i++) old.bars[i] != bars[i],
      ].any((x) => x);
}
