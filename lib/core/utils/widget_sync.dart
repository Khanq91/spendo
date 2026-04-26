import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../../features/categories/data/category_repository.dart';

const _kAppGroupId = 'com.kg.spendo.spendo';

// Emoji map cho widget (widget dùng emoji vì là TextView Android)
const _iconEmojiMap = {
  'restaurant': '🍜',
  'directions_car': '🚗',
  'school': '📚',
  'sports_esports': '🎮',
  'favorite': '💊',
  'shopping_bag': '🛍️',
  'work': '💼',
  'laptop': '💻',
  'storefront': '🏪',
  'card_giftcard': '🎁',
  'home': '🏠',
  'flight': '✈️',
  'movie': '🎬',
  'fitness_center': '💪',
  'pets': '🐾',
  'more_horiz': '📦',
};

class WidgetSync {
  static Future<void> syncCategories() async {
    try {
      final cats = await CategoryRepository().getByType(isIncome: false);
      final top4 = cats.take(4).map((c) => {
        'id': c.id,
        'name': c.name,
        'emoji': _iconEmojiMap[c.iconName] ?? '💰',
      }).toList();

      await HomeWidget.saveWidgetData(
        'widget_categories',
        jsonEncode(top4),
      );

      await HomeWidget.updateWidget(
        androidName: 'SpendoWidgetSmall',
      );
      await HomeWidget.updateWidget(
        androidName: 'SpendoWidgetMedium',
      );
    } catch (_) {
      // Widget sync thất bại không ảnh hưởng app
    }
  }
}