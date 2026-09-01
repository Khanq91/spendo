import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppVisualMode {
  normal,
  fancy;

  static AppVisualMode fromName(String? value) {
    return AppVisualMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppVisualMode.normal,
    );
  }
}

const appVisualModePrefsKey = 'app_visual_mode';

final visualModeProvider =
    StateNotifierProvider<VisualModeNotifier, AppVisualMode>(
      (ref) => VisualModeNotifier(),
    );

class VisualModeNotifier extends StateNotifier<AppVisualMode> {
  VisualModeNotifier() : super(AppVisualMode.normal) {
    _load();
  }

  /// Set once the user picks a mode, so the initial read cannot overwrite it.
  ///
  /// Reading preferences is asynchronous: a choice made in the first moments
  /// after launch — picking "Xịn xò" on the welcome page, say — used to be
  /// silently reverted when [_load] resolved a beat later.
  bool _chosen = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (_chosen || !mounted) return;
    state = AppVisualMode.fromName(prefs.getString(appVisualModePrefsKey));
  }

  Future<void> setMode(AppVisualMode mode) async {
    _chosen = true;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appVisualModePrefsKey, mode.name);
  }
}
