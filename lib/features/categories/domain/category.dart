import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String colorHex;
  final String iconName;
  final bool isDefault;
  final bool isIncome;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
    required this.isDefault,
    required this.isIncome,
    required this.sortOrder,
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String,
      iconName: map['icon_name'] as String,
      isDefault: (map['is_default'] as int) == 1,
      isIncome: (map['is_income'] as int) == 1,
      sortOrder: map['sort_order'] as int,
    );
  }
}