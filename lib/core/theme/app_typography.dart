import 'package:flutter/material.dart';

/// Type scale from `design_handoff_spendo_redesign/01-tokens.md`.
///
/// The handoff specifies Figtree + Caprasimo. Neither ships Vietnamese glyphs
/// (verified against the Google Fonts metadata and the upstream binaries:
/// Figtree is missing 92 of 98 Vietnamese codepoints, Caprasimo 82), and this
/// app is entirely Vietnamese, so accented characters would fall back to the
/// system font mid-word. They are replaced by the nearest equivalents that
/// cover Vietnamese completely and support tabular figures, keeping the scale,
/// weights and spacing of the spec unchanged:
///   Figtree   -> Plus Jakarta Sans (geometric-humanist sans, UI)
///   Caprasimo -> Baloo 2 (rounded heavy display, screen titles)
/// Both are bundled as assets — the app is offline-first, so no runtime fetch.
class AppTypography {
  const AppTypography._();

  /// Body/UI font.
  static const fontFamily = 'PlusJakartaSans';

  /// Display font for screen titles and brand moments.
  static const displayFamily = 'Baloo2';

  /// Amounts must not jitter while animating, so every numeric style opts into
  /// tabular figures.
  static const tabular = <FontFeature>[FontFeature.tabularFigures()];

  static TextTheme textTheme(Color onSurface, Color onSurfaceVariant) {
    return TextTheme(
      // Screen titles — display font.
      titleLarge: TextStyle(
        fontFamily: displayFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: onSurface,
        height: 1.25,
      ),
      // Balance / sheet amount.
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: onSurface,
        fontFeatures: tabular,
      ),
      // Amount inside a sheet or card.
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: onSurface,
        fontFeatures: tabular,
      ),
      // Sheet title.
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Row title.
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: onSurface),
      bodySmall: TextStyle(fontSize: 13, color: onSurfaceVariant),
      // Section header / chip / nav label.
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: onSurfaceVariant,
      ),
      // Label under an icon.
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: onSurfaceVariant,
      ),
    );
  }
}
