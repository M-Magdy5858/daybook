import 'dart:math' as math;

import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Draws a ring: a faint full circle (the track) with an arc on top for
/// [progress]. The arc starts at 12 o'clock and goes clockwise.
class RingPainter extends CustomPainter {
  RingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 10,
  });

  /// 0.0 to 1.0.
  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 12 o'clock
      2 * math.pi * progress.clamp(0, 1),
      false,
      arc,
    );
  }

  // Only redraw when something we draw actually changed.
  @override
  bool shouldRepaint(RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

/// A [RingPainter] that animates to each new [value].
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 120,
    this.color,
    this.strokeWidth = 10,
    this.child,
  });

  /// 0.0 to 1.0.
  final double value;
  final double size;

  /// Defaults to the theme's primary color.
  final Color? color;
  final double strokeWidth;

  /// Shown in the middle, e.g. "3 / 5".
  final Widget? child;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  // vsync: this ties the animation to screen refreshes; the mixin provides it.
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late Animation<double> _value = AlwaysStoppedAnimation(widget.value);

  /// Runs when the parent rebuilds this widget with new parameters.
  @override
  void didUpdateWidget(ProgressRing old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _value = Tween(begin: _value.value, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.primary;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => CustomPaint(
          painter: RingPainter(
            progress: _value.value,
            color: color,
            strokeWidth: widget.strokeWidth,
          ),
          child: child,
        ),
        // Built once, not on every animation frame.
        child: Center(child: widget.child),
      ),
    );
  }
}
