import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/core/theme/app_typography.dart';
import 'package:spendo/core/theme/spendo_colors.dart';

void main() {
  group('light scheme carries the Organic tokens', () {
    final theme = AppTheme.light(AppColorScheme.roseDefault);
    final cs = theme.colorScheme;

    test('surface family is the cream/sand ramp, not Material defaults', () {
      expect(cs.surface, const Color(0xFFFAF1E8));
      expect(cs.surfaceContainerLowest, const Color(0xFFFFFDF9));
      expect(cs.surfaceContainerLow, const Color(0xFFF5E9DA));
      expect(cs.surfaceContainer, const Color(0xFFEFE0CC));
      expect(cs.surfaceContainerHighest, const Color(0xFFE2CDB1));
      expect(cs.onSurface, const Color(0xFF221A12));
      expect(cs.onSurfaceVariant, const Color(0xFF57493B));
      expect(cs.outlineVariant, const Color(0xFFDCC9AF));
    });

    test('scaffold follows surface so every screen sits on cream', () {
      expect(theme.scaffoldBackgroundColor, cs.surface);
    });

    test('primary drives buttons, brand stays reserved for FAB/nav', () {
      expect(cs.primary, const Color(0xFF8C4A5E));
      expect(theme.spendo.brand, const Color(0xFFF06292));
      expect(theme.spendo.onBrand, const Color(0xFF551D30));
      expect(
        theme.floatingActionButtonTheme.backgroundColor,
        theme.spendo.brand,
      );
      expect(
        theme.floatingActionButtonTheme.foregroundColor,
        theme.spendo.onBrand,
      );
    });

    test('income and expense are the warm olive/terracotta pair', () {
      expect(theme.spendo.income, const Color(0xFF5A7230));
      expect(theme.spendo.expense, const Color(0xFFB23A2E));
      expect(theme.spendo.warning, const Color(0xFFB26A00));
    });
  });

  group('dark scheme swaps values, keeps the roles', () {
    final theme = AppTheme.dark(AppColorScheme.roseDefault);
    final cs = theme.colorScheme;

    test('surface is warm brown rather than pure black', () {
      expect(cs.surface, const Color(0xFF1C140C));
      expect(cs.onSurface, const Color(0xFFF0E4D3));
    });

    test('brand survives dark mode but the FAB loses its shadow', () {
      expect(theme.spendo.brand, const Color(0xFFF06292));
      expect(theme.floatingActionButtonTheme.elevation, 0);
    });

    test('primary is lifted for contrast on dark surfaces', () {
      expect(cs.primary, const Color(0xFFE9A4B5));
      expect(cs.onPrimary, const Color(0xFF4A2231));
    });
  });

  group('accent choices', () {
    test('only brand and the primary ramp change between schemes', () {
      final rose = AppTheme.light(AppColorScheme.roseDefault);
      for (final scheme in AppColorScheme.values) {
        final theme = AppTheme.light(scheme);
        // The cream surface family is shared by every accent.
        expect(theme.colorScheme.surface, rose.colorScheme.surface);
        expect(
          theme.colorScheme.surfaceContainer,
          rose.colorScheme.surfaceContainer,
        );
        expect(theme.colorScheme.onSurface, rose.colorScheme.onSurface);
        // ...while the accent itself does move.
        expect(theme.spendo.brand, scheme.brandColor);
      }
    });

    test('a non-default accent really changes primary', () {
      expect(
        AppTheme.light(AppColorScheme.emeraldWealth).colorScheme.primary,
        isNot(AppTheme.light(AppColorScheme.roseDefault).colorScheme.primary),
      );
    });
  });

  group('typography', () {
    test('uses the bundled families, not the system font', () {
      final theme = AppTheme.light(AppColorScheme.roseDefault);
      // Body copy inherits the UI family...
      expect(theme.textTheme.bodyMedium?.fontFamily, AppTypography.fontFamily);
      expect(theme.textTheme.titleSmall?.fontFamily, AppTypography.fontFamily);
      // ...while screen titles keep the display family.
      expect(
        theme.textTheme.titleLarge?.fontFamily,
        AppTypography.displayFamily,
      );
    });

    test('amount styles opt into tabular figures so digits do not jitter', () {
      final t = AppTheme.light(AppColorScheme.roseDefault).textTheme;
      for (final style in [t.displaySmall, t.headlineSmall]) {
        expect(
          style?.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    });
  });

  test('SpendoColors lerps between light and dark without throwing', () {
    final mid = SpendoColors.light.lerp(SpendoColors.dark, 0.5);
    expect(mid.brand, SpendoColors.light.brand);
    expect(mid.income, isNot(SpendoColors.light.income));
  });
}
