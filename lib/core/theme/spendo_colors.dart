import 'package:flutter/material.dart';

/// Tokens that live outside the Material 3 [ColorScheme] roles.
///
/// Source of truth: `design_handoff_spendo_redesign/01-tokens.md`.
/// Brand is deliberately separate from `primary`: it is used ONLY for the FAB
/// and the bottom-nav tab indicator, while `primary` drives buttons/links.
@immutable
class SpendoColors extends ThemeExtension<SpendoColors> {
  const SpendoColors({
    required this.brand,
    required this.onBrand,
    required this.income,
    required this.expense,
    required this.warning,
    required this.dashedOutline,
  });

  /// #F06292 — FAB + tab indicator only.
  final Color brand;

  /// Icon/label drawn on top of [brand].
  final Color onBrand;

  /// Incoming money.
  final Color income;

  /// Outgoing money.
  final Color expense;

  /// Approaching a budget limit (>= 85%).
  final Color warning;

  /// Border of the dashed "add" affordances.
  final Color dashedOutline;

  static const light = SpendoColors(
    brand: Color(0xFFF06292),
    onBrand: Color(0xFF551D30),
    income: Color(0xFF5A7230),
    expense: Color(0xFFB23A2E),
    warning: Color(0xFFB26A00),
    dashedOutline: Color(0xFFB7A388),
  );

  static const dark = SpendoColors(
    brand: Color(0xFFF06292),
    onBrand: Color(0xFF551D30),
    income: Color(0xFFA9C77C),
    expense: Color(0xFFE88D7C),
    warning: Color(0xFFE8A94E),
    dashedOutline: Color(0xFF55442F),
  );

  @override
  SpendoColors copyWith({
    Color? brand,
    Color? onBrand,
    Color? income,
    Color? expense,
    Color? warning,
    Color? dashedOutline,
  }) {
    return SpendoColors(
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      dashedOutline: dashedOutline ?? this.dashedOutline,
    );
  }

  @override
  SpendoColors lerp(covariant SpendoColors? other, double t) {
    if (other == null) return this;
    return SpendoColors(
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      dashedOutline: Color.lerp(dashedOutline, other.dashedOutline, t)!,
    );
  }
}

/// `Theme.of(context).spendo` — shorthand for the token set above.
extension SpendoColorsX on ThemeData {
  SpendoColors get spendo => extension<SpendoColors>() ?? SpendoColors.light;
}

/// `context.spendo` from any widget.
extension SpendoColorsContextX on BuildContext {
  SpendoColors get spendo => Theme.of(this).spendo;
}
