import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One slice of the donut.
typedef DonutSlice = ({Color color, double value});

/// A ring split into colored slices, one `drawArc` per slice, each sweeping
/// `2π × (its share of the total)`. [center] sits in the hole.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.semanticsLabel,
    this.center,
    this.size = 180,
  });

  final List<DonutSlice> slices;
  final String semanticsLabel;
  final Widget? center;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _DonutPainter(
            slices,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.emptyColor);

  final List<DonutSlice> slices;
  final Color emptyColor;

  static const _stroke = 26.0;
  static const _gap = 0.02; // radians between slices

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - _stroke) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    final total = slices.fold(0.0, (sum, s) => sum + s.value);

    if (total <= 0) {
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = emptyColor);
      return;
    }
    var start = -math.pi / 2; // 12 o'clock
    for (final s in slices) {
      final sweep = 2 * math.pi * s.value / total;
      final gap = slices.length > 1 ? _gap : 0;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(0, sweep - gap),
        false,
        paint..color = s.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.emptyColor != emptyColor || !_sameSlices(old.slices, slices);

  static bool _sameSlices(List<DonutSlice> a, List<DonutSlice> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
