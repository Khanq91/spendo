import 'package:flutter/material.dart';

/// Bảng màu chung — dùng cho category picker, wallet picker, bất kỳ color picker nào.
class AppColors {
  AppColors._();

  static const List<String> palette = [
    '#FF6B6B',
    '#FF8E53',
    '#FFA726',
    '#FFEAA7',
    '#96CEB4',
    '#4ECDC4',
    '#45B7D1',
    '#42A5F5',
    '#6C63FF',
    '#9C8FFF',
    '#DDA0DD',
    '#EC407A',
    '#66BB6A',
    '#B0BEC5',
  ];

  static Color fromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
