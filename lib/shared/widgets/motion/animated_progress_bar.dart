import 'package:flutter/material.dart';

import 'motion_spec.dart';

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.trackColor,
    this.valueColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.semanticLabel,
  });

  final double value;
  final double height;
  final Color? trackColor;
  final Color? valueColor;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clampedValue = value.clamp(0.0, 1.0);
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    return Semantics(
      label: semanticLabel,
      value: '${(clampedValue * 100).round()}%',
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          height: height,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: clampedValue, end: clampedValue),
            duration: reduceMotion ? Duration.zero : appMotion.valueDuration,
            curve: appMotion.curveStandard,
            builder: (context, animatedValue, _) {
              return LinearProgressIndicator(
                value: animatedValue,
                minHeight: height,
                backgroundColor:
                    trackColor ?? cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  valueColor ?? cs.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
