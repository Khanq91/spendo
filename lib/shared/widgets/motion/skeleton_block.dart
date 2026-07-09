import 'package:flutter/material.dart';

import 'motion_spec.dart';

class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionSpec.shouldReduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final baseColor = cs.surfaceContainerHighest.withValues(alpha: 0.55);
    final pulseColor = cs.surfaceContainerHighest.withValues(alpha: 0.9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color =
            MotionSpec.shouldReduceMotion(context)
                ? baseColor
                : Color.lerp(baseColor, pulseColor, _controller.value)!;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.borderRadius,
          ),
          child: child,
        );
      },
      child: SizedBox(width: widget.width, height: widget.height),
    );
  }
}
