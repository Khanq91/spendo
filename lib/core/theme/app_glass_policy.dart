import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

abstract final class AppGlassPolicy {
  static const adaptiveQualityPrefsKey = 'spendo_adaptive_glass_quality';

  // Keep the inherited default conservative. Individual fixed focal surfaces
  // may request premium, but the root adaptive scope can still cap them.
  static const themeQuality = GlassQuality.standard;
  static const interactiveQuality = GlassQuality.standard;
  static const focalQuality = GlassQuality.premium;

  static const minimumAdaptiveQuality = GlassQuality.minimal;
  static const maximumAdaptiveQuality = GlassQuality.premium;

  static GlassQuality? parseSavedQuality(String? value) {
    if (value == null) return null;

    for (final quality in GlassQuality.values) {
      if (quality.name == value) return quality;
    }

    return null;
  }
}
