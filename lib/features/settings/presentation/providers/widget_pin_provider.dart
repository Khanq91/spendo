import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const _kKey = 'widget_pinned_ids';

final widgetPinnedIdsProvider =
StateNotifierProvider<WidgetPinnedNotifier, List<String>>(
      (ref) => WidgetPinnedNotifier(),
);

class WidgetPinnedNotifier extends StateNotifier<List<String>> {
  WidgetPinnedNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw != null) {
      state = List<String>.from(jsonDecode(raw));
    }
  }

  Future<void> setSlot(int slot, String categoryId) async {
    final next = List<String>.from(state);
    // Đảm bảo list có đủ 4 phần tử
    while (next.length < 4) next.add('');
    next[slot] = categoryId;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(next));
  }

  Future<void> clearSlot(int slot) async {
    final next = List<String>.from(state);
    while (next.length < 4) next.add('');
    next[slot] = '';
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, jsonEncode(next));
  }
}