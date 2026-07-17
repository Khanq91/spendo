import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_colors.dart';
import 'package:spendo/core/utils/currency_formatter.dart';

void main() {
  test('AppColors keeps the existing RGB hex contract', () {
    expect(AppColors.toHex(const Color(0x7F123456)), '#123456');
  });

  test('formatVND keeps Vietnamese grouping and currency suffix', () {
    expect(formatVND(1234567), '1.234.567 ₫');
  });
}
