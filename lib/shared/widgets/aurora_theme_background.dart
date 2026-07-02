import 'dart:math' as math;

import 'package:flutter/material.dart';

class AuroraThemeBackground extends StatefulWidget {
  const AuroraThemeBackground({super.key});

  @override
  State<AuroraThemeBackground> createState() => _AuroraThemeBackgroundState();
}

class _AuroraThemeBackgroundState extends State<AuroraThemeBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _AuroraPainter(
            progress: _controller.value,
            primary: cs.primary,
            secondary: cs.secondary,
            tertiary: cs.tertiary,
            surface: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.surface,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surface);
    _drawRibbon(canvas, size, primary, 0.18, 0.16, 0.18);
    _drawRibbon(canvas, size, secondary, 0.12, 0.52, 0.31);
    _drawRibbon(canvas, size, tertiary, 0.10, 0.82, 0.47);
  }

  void _drawRibbon(
    Canvas canvas,
    Size size,
    Color color,
    double opacity,
    double yFactor,
    double phase,
  ) {
    final path = Path();
    final wave =
        math.sin((progress + phase) * math.pi * 2) * size.height * 0.04;
    final y = size.height * yFactor + wave;

    path
      ..moveTo(0, y)
      ..cubicTo(
        size.width * 0.24,
        y - size.height * 0.18,
        size.width * 0.62,
        y + size.height * 0.14,
        size.width,
        y - size.height * 0.06,
      )
      ..lineTo(size.width, y + size.height * 0.22)
      ..cubicTo(
        size.width * 0.66,
        y + size.height * 0.34,
        size.width * 0.22,
        y + size.height * 0.18,
        0,
        y + size.height * 0.32,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.tertiary != tertiary ||
        oldDelegate.surface != surface;
  }
}
