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

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppVisualMode.fromName(prefs.getString(appVisualModePrefsKey));
  }

  Future<void> setMode(AppVisualMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(appVisualModePrefsKey, mode.name);
  }
}
