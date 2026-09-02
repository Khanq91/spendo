import 'package:flutter/material.dart';

@immutable
class MotionSpec {
  const MotionSpec({
    this.tapDownDuration = const Duration(milliseconds: 100),
    this.tapUpDuration = const Duration(milliseconds: 140),
    this.valueDuration = const Duration(milliseconds: 360),
    this.listDuration = const Duration(milliseconds: 260),
    this.chartDuration = const Duration(milliseconds: 380),
    this.screenDuration = const Duration(milliseconds: 420),
    this.staggerShort = const Duration(milliseconds: 30),
    this.revealStagger = const Duration(milliseconds: 80),
    this.curveStandard = Curves.easeOutCubic,
    this.curveLayout = Curves.easeInOutCubic,
    this.curveMaterial = Curves.fastOutSlowIn,
  });

  final Duration tapDownDuration;
  final Duration tapUpDuration;
  final Duration valueDuration;
  final Duration listDuration;
  final Duration chartDuration;
  final Duration screenDuration;
  final Duration staggerShort;

  /// Delay between rows that reveal together (react-bits Animated List).
  final Duration revealStagger;
  final Curve curveStandard;
  final Curve curveLayout;
  final Curve curveMaterial;

  Duration whenMotionAllowed(BuildContext context, Duration duration) {
    return shouldReduceMotion(context) ? Duration.zero : duration;
  }

  static bool shouldReduceMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return false;
    return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
  }
}

const appMotion = MotionSpec();
