import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Color scheme palette
// ---------------------------------------------------------------------------

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

  /// The Material 3 seed that drives the entire ColorScheme.
  Color get seedColor => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFFAD6E7F),
    AppColorScheme.indigoMidnight => const Color(0xFF5C6BC0),
    AppColorScheme.emeraldWealth => const Color(0xFF00897B),
    AppColorScheme.slatePremium => const Color(0xFF78909C),
    AppColorScheme.amberWarm => const Color(0xFFFFB300),
  };

  /// Representative swatch shown in the color picker.
  Color get swatch => switch (this) {
    AppColorScheme.roseDefault => const Color(0xFFAD6E7F),
    AppColorScheme.indigoMidnight => const Color(0xFF5C6BC0),
    AppColorScheme.emeraldWealth => const Color(0xFF00897B),
    AppColorScheme.slatePremium => const Color(0xFF78909C),
    AppColorScheme.amberWarm => const Color(0xFFFFB300),
  };
}

// ---------------------------------------------------------------------------
// AppTheme
// ---------------------------------------------------------------------------

class AppTheme {
  // ------------------------------------------------------------------
  // Semantic colors — fixed across ALL themes.
  // These represent meaning (income / expense), not brand.
  // ------------------------------------------------------------------
  static const incomeColor = Color(0xFF43A047);
  static const expenseColor = Color(0xFFF06292);
  static const expenseAltColor = Color(0xFFE53935); // destructive actions

  // ------------------------------------------------------------------
  // Light theme
  // ------------------------------------------------------------------
  static ThemeData light(AppColorScheme scheme) {
    final seed = scheme.seedColor;
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFF0F0F0),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: cs.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: 22);
          }
          return const IconThemeData(color: Color(0xFF9E9E9E), size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            );
          }
          return const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E));
        }),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: Colors.grey.shade200),
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade100,
        thickness: 0.5,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.white,
        minLeadingWidth: 0,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Dark theme
  // ------------------------------------------------------------------
  static ThemeData dark(AppColorScheme scheme) {
    final seed = scheme.seedColor;
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF1E1E1E),
      surfaceContainerHighest: const Color(0xFF2A2A2A),
      onSurface: const Color(0xFFEEEEEE),
      onSurfaceVariant: const Color(0xFFAAAAAA),
      outline: const Color(0xFF444444),
      outlineVariant: const Color(0xFF333333),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF111111),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111111),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: cs.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: 22);
          }
          return const IconThemeData(color: Color(0xFF757575), size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            );
          }
          return const TextStyle(fontSize: 11, color: Color(0xFF757575));
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Color(0xFF333333)),
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A2A),
        thickness: 0.5,
        space: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF666666)),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 4),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Color(0xFF1E1E1E),
        minLeadingWidth: 0,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
