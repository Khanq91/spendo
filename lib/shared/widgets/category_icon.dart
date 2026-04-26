import 'package:flutter/material.dart';
import '../../core/utils/category_icons.dart';
import '../../features/categories/domain/category.dart';

class CategoryIconWidget extends StatelessWidget {
  final Category? category;
  final double size;
  final double iconSize;

  const CategoryIconWidget({
    super.key,
    required this.category,
    this.size = 40,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final color = category?.color ?? Colors.grey;
    final icon = categoryIcon(category?.iconName ?? '');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}