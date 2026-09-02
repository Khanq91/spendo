import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/spendo_colors.dart';
import 'motion/motion_spec.dart';
import 'particle_field/particle_field.dart';

/// The "Xịn xò" backdrop: a drifting particle field in the theme's colours,
/// softened by one light blur pass, over the scaffold colour.
///
/// The field is Snipz `particle_field` copied as-is; this widget only sets
/// its palette and density. The blur is one `ImageFiltered` over the whole
/// layer rather than the field's per-particle `softParticles`, which costs a
/// MaskFilter per dot per frame. The flat colour is painted underneath, not
/// inside the field, so the blur never bleeds the background past the edges.
class ParticleThemeBackground extends StatelessWidget {
  const ParticleThemeBackground({super.key, this.blurSigma = 1.6});

  /// Gaussian radius of the softening pass, in logical px.
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final spendo = theme.spendo;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: theme.scaffoldBackgroundColor),
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
              tileMode: TileMode.decal,
            ),
            child: ParticleField(
              colors: [spendo.brand, cs.primary, cs.secondary, cs.tertiary],
              // Calmer than the demo defaults: a finance app's backdrop
              // should read as still unless you look at it.
              density: 4,
              maxParticles: 260,
              baseSize: 3,
              speed: 0.6,
              // Parallax follows the finger; the tilt sensor went with the
              // aurora (PLAN 2.4).
              interactive: true,
              animate: !MotionSpec.shouldReduceMotion(context),
            ),
          ),
        ],
      ),
    );
  }
}
