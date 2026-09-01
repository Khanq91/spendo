import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/categories/domain/category.dart';

const _iconEmojiMap = {
  'restaurant': '🍜', 'directions_car': '🚗', 'school': '📚',
  'sports_esports': '🎮', 'favorite': '💊', 'shopping_bag': '🛍️',
  'work': '💼', 'laptop': '💻', 'storefront': '🏪',
  'card_giftcard': '🎁', 'home': '🏠', 'flight': '✈️',
  'movie': '🎬', 'fitness_center': '💪', 'pets': '🐾', 'more_horiz': '📦',
};

/// Resolves the four widget slots from the pinned ids the user set.
///
/// One definition shared by the sync and by the Widget settings page, so the
/// preview on that page cannot disagree with what lands on the home screen.
///
/// A slot the user never touched — or one whose category has since been
/// deleted — falls back to the next unused expense category. Slots only stay
/// null when the user genuinely has fewer than four; the widget then shows a
/// bare "+" for those rather than a name that is not theirs. Empty slots keep
/// their position, because the 2×2 grid is positional.
List<Category?> resolveWidgetSlots(
  List<String> pinnedIds,
  List<Category> expenseCategories,
) {
  final byId = {for (final c in expenseCategories) c.id: c};
  final slots = List<Category?>.filled(4, null);
  final used = <String>{};

  for (var i = 0; i < 4; i++) {
    final id = i < pinnedIds.length ? pinnedIds[i] : '';
    final cat = id.isEmpty ? null : byId[id];
    if (cat != null && used.add(cat.id)) slots[i] = cat;
  }

  final spare = expenseCategories
      .where((c) => !used.contains(c.id))
      .iterator;
  for (var i = 0; i < 4; i++) {
    if (slots[i] != null) continue;
    if (!spare.moveNext()) break;
    slots[i] = spare.current;
  }

  return slots;
}

class WidgetSync {
  static Future<void> syncCategories() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final allCats = await CategoryRepository().getByType(isIncome: false);

      // Đọc pinned IDs
      final pinnedRaw = prefs.getString('widget_pinned_ids');
      List<String> pinnedIds = [];
      if (pinnedRaw != null) {
        pinnedIds = List<String>.from(jsonDecode(pinnedRaw));
      }

      final slots = resolveWidgetSlots(pinnedIds, allCats);

      // Empty slots stay in the list as blanks so slot 3 keeps its position
      // when slot 2 has no category — the grid is positional.
      final data = slots
          .map(
            (c) => {
              'id': c?.id ?? '',
              'name': c?.name ?? '',
              'emoji': c == null ? '' : _iconEmojiMap[c.iconName] ?? '💰',
            },
          )
          .toList();

        await prefs.setString('widget_categories', jsonEncode(data));

        final verify = prefs.getString('widget_categories');
        debugPrint('[WidgetSync] saved: $verify');

        await HomeWidget.updateWidget(
          androidName: 'SpendoWidgetSmall',
        );
        await HomeWidget.updateWidget(
          androidName: 'SpendoWidgetMedium',
        );
      } catch (e) {
        debugPrint('[WidgetSync] error: $e');
      }
  }
}