import 'package:flutter/material.dart';

import 'motion_spec.dart';

class AnimatedMoneyText extends StatelessWidget {
  const AnimatedMoneyText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.privacyMask,
    this.animate = true,
    this.textAlign,
    this.overflow,
  });

  final num value;
  final String Function(num value) formatter;
  final TextStyle? style;
  final String? privacyMask;
  final bool animate;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? DefaultTextStyle.of(context).style)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final masked = privacyMask != null;
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    if (!animate || masked || reduceMotion) {
      return Text(
        privacyMask ?? formatter(value),
        style: effectiveStyle,
        textAlign: textAlign,
        overflow: overflow,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: appMotion.valueDuration,
      curve: appMotion.curveStandard,
      builder: (context, animatedValue, _) {
        return Text(
          formatter(animatedValue),
          style: effectiveStyle,
          textAlign: textAlign,
          overflow: overflow,
        );
      },
    );
  }
}
