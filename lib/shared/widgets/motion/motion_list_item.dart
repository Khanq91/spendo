import 'package:flutter/material.dart';

import 'motion_spec.dart';

class MotionListItem extends StatelessWidget {
  const MotionListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.enabled = true,
    this.offset = const Offset(0, 10),
  });

  final Widget child;
  final int index;
  final bool enabled;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (!enabled || MotionSpec.shouldReduceMotion(context)) return child;

    final delay = appMotion.staggerShort * index.clamp(0, 6);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: appMotion.listDuration + delay,
      curve: appMotion.curveStandard,
      builder: (context, value, child) {
        final easedValue = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: easedValue,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - easedValue),
              offset.dy * (1 - easedValue),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
