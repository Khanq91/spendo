import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'spendo_colors.dart';

// ---------------------------------------------------------------------------
// Color scheme palette
// ---------------------------------------------------------------------------

/// The five accent choices offered in Settings.
///
/// Per `01-tokens.md`, only the brand colour and the primary ramp change
/// between them — the cream/brown surface family stays identical, so the
/// scheme is declared explicitly instead of regenerated with `fromSeed`.
enum AppColorScheme {
  roseDefault,
  indigoMidnight,
  emeraldWealth,
  slatePremium,
  amberWarm;

  /// Human-readable label shown in Settings UI.
  String get label => switch (this) {
    AppColorScheme.roseDefault => 'Rose (Mặc định)',
    AppColorScheme.indigoMidnight => 'Indigo Midnight',
    AppColorScheme.emeraldWealth => 'Emerald Wealth',
    AppColorScheme.slatePremium => 'Slate Premium',
    AppColorScheme.amberWarm => 'Amber Warm',
  };

  /// FAB + tab indicator.
  Color get brandColor => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFFF06292),
    AppColorScheme.indigoMidnight => const Color(0xFF7986CB),
    AppColorScheme.emeraldWealth => const Color(0xFF4DB6A0),
    AppColorScheme.slatePremium => const Color(0xFF90A4AE),
    AppColorScheme.amberWarm => const Color(0xFFFFB300),
  };

  /// Icon/label drawn on top of [brandColor].
  Color get onBrandColor => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFF551D30),
    AppColorScheme.indigoMidnight => const Color(0xFF1B2154),
    AppColorScheme.emeraldWealth => const Color(0xFF00382E),
    AppColorScheme.slatePremium => const Color(0xFF1F2A30),
    AppColorScheme.amberWarm => const Color(0xFF432B00),
  };

  // -- Primary ramp -- light ------------------------------------------------

  Color get _primaryLight => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFF8C4A5E),
    AppColorScheme.indigoMidnight => const Color(0xFF4A5296),
    AppColorScheme.emeraldWealth => const Color(0xFF1E6A5C),
    AppColorScheme.slatePremium => const Color(0xFF4A5C66),
    AppColorScheme.amberWarm => const Color(0xFF8A5A17),
  };

  Color get _primaryContainerLight => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFFFFD9E1),
    AppColorScheme.indigoMidnight => const Color(0xFFDDE1FF),
    AppColorScheme.emeraldWealth => const Color(0xFFC7EFE5),
    AppColorScheme.slatePremium => const Color(0xFFD6E4EC),
    AppColorScheme.amberWarm => const Color(0xFFFFE0B2),
  };

  Color get _onPrimaryContainerLight => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFF703346),
    AppColorScheme.indigoMidnight => const Color(0xFF343C7E),
    AppColorScheme.emeraldWealth => const Color(0xFF0C5245),
    AppColorScheme.slatePremium => const Color(0xFF35464F),
    AppColorScheme.amberWarm => const Color(0xFF6B4406),
  };

  // -- Primary ramp -- dark -------------------------------------------------

  Color get _primaryDark => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFFE9A4B5),
    AppColorScheme.indigoMidnight => const Color(0xFFB7C0FF),
    AppColorScheme.emeraldWealth => const Color(0xFF8AD5C4),
    AppColorScheme.slatePremium => const Color(0xFFB2C6D1),
    AppColorScheme.amberWarm => const Color(0xFFF2C078),
  };

  Color get _onPrimaryDark => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFF4A2231),
    AppColorScheme.indigoMidnight => const Color(0xFF1B2154),
    AppColorScheme.emeraldWealth => const Color(0xFF00382E),
    AppColorScheme.slatePremium => const Color(0xFF1F2A30),
    AppColorScheme.amberWarm => const Color(0xFF432B00),
  };

  Color get _primaryContainerDark => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFF703346),
    AppColorScheme.indigoMidnight => const Color(0xFF343C7E),
    AppColorScheme.emeraldWealth => const Color(0xFF0C5245),
    AppColorScheme.slatePremium => const Color(0xFF35464F),
    AppColorScheme.amberWarm => const Color(0xFF6B4406),
  };

  /// Representative swatch shown in the color picker.
  Color get swatch => brandColor;
}

// ---------------------------------------------------------------------------
// AppTheme
// ---------------------------------------------------------------------------

class AppTheme {
  // ------------------------------------------------------------------
  // Semantic colours — meaning (income / expense), not brand.
  //
  // These are the light-mode token values. Widgets that can reach a
  // BuildContext should prefer `context.spendo.income` / `.expense`, which
  // also resolve correctly in dark mode; these constants remain for the
  // call sites that build styles outside the widget tree.
  // ------------------------------------------------------------------
  static const incomeColor = Color(0xFF5A7230);
  static const expenseColor = Color(0xFFB23A2E);

  /// Destructive actions. Same hue family as [expenseColor] but the M3
  /// `error` role — kept separate so "spent money" and "something went
  /// wrong" stay distinguishable.
  static const expenseAltColor = Color(0xFFBA1A1A);

  // ------------------------------------------------------------------
  // Shared shape tokens (01-tokens.md — "Hình khối & spacing").
  // ------------------------------------------------------------------
  static const radiusCard = 16.0;
  static const radiusCardFeature = 20.0;
  static const radiusSheet = 28.0;
  static const radiusInput = 12.0;
  static const radiusPill = 999.0;

  // ------------------------------------------------------------------
  // Light theme
  // ------------------------------------------------------------------
  static ThemeData light(AppColorScheme scheme) {
    const cs = ColorScheme.light(
      primary: Color(0xFF8C4A5E),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFFD9E1),
      onPrimaryContainer: Color(0xFF703346),
      secondary: Color(0xFF48513A),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE3E8D0),
      onSecondaryContainer: Color(0xFF48513A),
      tertiary: Color(0xFF7A4A24),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFFFDCBF),
      onTertiaryContainer: Color(0xFF7A4A24),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFFAF1E8),
      onSurface: Color(0xFF221A12),
      onSurfaceVariant: Color(0xFF57493B),
      surfaceContainerLowest: Color(0xFFFFFDF9),
      surfaceContainerLow: Color(0xFFF5E9DA),
      surfaceContainer: Color(0xFFEFE0CC),
      surfaceContainerHigh: Color(0xFFE9D7C0),
      surfaceContainerHighest: Color(0xFFE2CDB1),
      outline: Color(0xFF897463),
      outlineVariant: Color(0xFFDCC9AF),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF372F26),
      onInverseSurface: Color(0xFFFDEEE0),
      inversePrimary: Color(0xFFE9A4B5),
    );

    final colorScheme = cs.copyWith(
      primary: scheme._primaryLight,
      primaryContainer: scheme._primaryContainerLight,
      onPrimaryContainer: scheme._onPrimaryContainerLight,
    );

    return _base(
      colorScheme: colorScheme,
      spendo: SpendoColors.light.copyWith(
        brand: scheme.brandColor,
        onBrand: scheme.onBrandColor,
      ),
      isDark: false,
    );
  }

  // ------------------------------------------------------------------
  // Dark theme
  // ------------------------------------------------------------------
  static ThemeData dark(AppColorScheme scheme) {
    const cs = ColorScheme.dark(
      primary: Color(0xFFE9A4B5),
      onPrimary: Color(0xFF4A2231),
      primaryContainer: Color(0xFF703346),
      onPrimaryContainer: Color(0xFFFFD9E1),
      secondary: Color(0xFFC7CFB4),
      onSecondary: Color(0xFF313924),
      secondaryContainer: Color(0xFF48513A),
      onSecondaryContainer: Color(0xFFE3E8D0),
      tertiary: Color(0xFFF0BC94),
      onTertiary: Color(0xFF4A2A0B),
      tertiaryContainer: Color(0xFF7A4A24),
      onTertiaryContainer: Color(0xFFFFDCBF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF1C140C),
      onSurface: Color(0xFFF0E4D3),
      onSurfaceVariant: Color(0xFFC9B79F),
      surfaceContainerLowest: Color(0xFF251B10),
      surfaceContainerLow: Color(0xFF2B2013),
      surfaceContainer: Color(0xFF342718),
      surfaceContainerHigh: Color(0xFF3B2E1C),
      surfaceContainerHighest: Color(0xFF453421),
      outline: Color(0xFF938068),
      outlineVariant: Color(0xFF55442F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFF0E4D3),
      onInverseSurface: Color(0xFF372F26),
      inversePrimary: Color(0xFF8C4A5E),
    );

    final colorScheme = cs.copyWith(
      primary: scheme._primaryDark,
      onPrimary: scheme._onPrimaryDark,
      primaryContainer: scheme._primaryContainerDark,
    );

    return _base(
      colorScheme: colorScheme,
      spendo: SpendoColors.dark.copyWith(
        brand: scheme.brandColor,
        onBrand: scheme.onBrandColor,
      ),
      isDark: true,
    );
  }

  // ------------------------------------------------------------------
  // Shared builder — both brightnesses differ only by token values.
  // ------------------------------------------------------------------
  static ThemeData _base({
    required ColorScheme colorScheme,
    required SpendoColors spendo,
    required bool isDark,
  }) {
    final textTheme = AppTypography.textTheme(
      colorScheme.onSurface,
      colorScheme.onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: <ThemeExtension<dynamic>>[spendo],
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: spendo.brand,
        foregroundColor: spendo.onBrand,
        elevation: isDark ? 0 : 2,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        hintStyle: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: colorScheme.surfaceContainerLow,
        minLeadingWidth: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: colorScheme.onSurfaceVariant,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusSheet),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: spendo.brand,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: spendo.onBrand, size: 20);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 20);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            );
          }
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          color: colorScheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusInput),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCardFeature),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }
}
