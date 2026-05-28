import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ThemeState {
  const ThemeState({
    this.mode = ThemeMode.system,
    this.colorScheme = AppColorScheme.roseDefault,
  });

  final ThemeMode mode;
  final AppColorScheme colorScheme;

  ThemeState copyWith({ThemeMode? mode, AppColorScheme? colorScheme}) {
    return ThemeState(
      mode: mode ?? this.mode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _load();
  }

  static const _keyMode = 'theme_mode';
  static const _keyColorScheme = 'theme_color_scheme';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final modeIndex = prefs.getInt(_keyMode) ?? 0;
    final schemeName = prefs.getString(_keyColorScheme);

    final mode =
        ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)];
    final scheme =
        schemeName != null
            ? AppColorScheme.values.firstWhere(
              (e) => e.name == schemeName,
              orElse: () => AppColorScheme.roseDefault,
            )
            : AppColorScheme.roseDefault;

    state = ThemeState(mode: mode, colorScheme: scheme);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, mode.index);
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    state = state.copyWith(colorScheme: scheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyColorScheme, scheme.name);
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

// ---------------------------------------------------------------------------
// Convenience providers — use these directly in MaterialApp
// ---------------------------------------------------------------------------

/// Replaces the old `themeModeProvider`.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themeProvider).mode,
);

final lightThemeProvider = Provider<ThemeData>(
  (ref) => AppTheme.light(ref.watch(themeProvider).colorScheme),
);

final darkThemeProvider = Provider<ThemeData>(
  (ref) => AppTheme.dark(ref.watch(themeProvider).colorScheme),
);
