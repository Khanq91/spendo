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

      List<Category> top4;

      if (pinnedIds.isNotEmpty && pinnedIds.any((id) => id.isNotEmpty)) {
        // Dùng đúng thứ tự slot user chọn
        final catMap = {for (final c in allCats) c.id: c};
        top4 = pinnedIds
            .map((id) => catMap[id])
            .whereType<Category>()
            .take(4)
            .toList();
        // Nếu chưa đủ 4, fill thêm từ allCats
        if (top4.length < 4) {
          final existing = top4.map((c) => c.id).toSet();
          for (final c in allCats) {
            if (!existing.contains(c.id)) top4.add(c);
            if (top4.length == 4) break;
          }
        }
      } else {
        top4 = allCats.take(4).toList();
      }

      final data = top4.map((c) => {
        'id': c.id,
        'name': c.name,
        'emoji': _iconEmojiMap[c.iconName] ?? '💰',
      }).toList();

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