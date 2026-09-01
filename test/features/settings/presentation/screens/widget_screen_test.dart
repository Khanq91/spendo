import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/settings/presentation/screens/widget_screen.dart';

const _categories = [
  Category(
    id: 'food',
    name: 'Ăn uống',
    colorHex: '#FF6B6B',
    iconName: 'restaurant',
    isDefault: true,
    isIncome: false,
    sortOrder: 0,
  ),
  Category(
    id: 'car',
    name: 'Di chuyển',
    colorHex: '#7A8A5E',
    iconName: 'directions_car',
    isDefault: true,
    isIncome: false,
    sortOrder: 1,
  ),
  Category(
    id: 'fun',
    name: 'Giải trí',
    colorHex: '#A5668B',
    iconName: 'movie',
    isDefault: false,
    isIncome: false,
    sortOrder: 2,
  ),
];

Widget _app() {
  return ProviderScope(
    overrides: [
      categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      home: const WidgetScreen(),
    ),
  );
}

void main() {
  testWidgets('every slot gets a full row with a real clear button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'widget_pinned_ids': '["food","car","",""]',
    });

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (var i = 1; i <= 4; i++) {
      expect(find.text('Slot $i'), findsOneWidget);
    }

    // Two pinned rows, two empty ones — and the clear affordance is a labelled
    // chip, not the 12px `×` the audit flagged
    // (`29-widget-pin-picker-sheet.md` §L).
    expect(find.text('Chọn danh mục…'), findsNWidgets(2));
    expect(find.text('Bỏ ghim'), findsNWidgets(2));

    final chip = find.ancestor(
      of: find.text('Bỏ ghim').first,
      matching: find.byType(GestureDetector),
    );
    expect(tester.getSize(chip.first).height, greaterThanOrEqualTo(30));
  });

  testWidgets('the preview shows pinned categories and dashed empty cells', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'widget_pinned_ids': '["food","","",""]',
    });

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('XEM TRƯỚC (2×2)'), findsOneWidget);
    // One pinned name in the preview plus one in the slot row.
    expect(find.text('Ăn uống'), findsNWidgets(2));
    expect(find.text('Trống'), findsNWidgets(3));
  });

  testWidgets('the picker greys out a category already in another slot', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'widget_pinned_ids': '["food","","",""]',
    });

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chọn danh mục…').first);
    await tester.pumpAndSettle();

    expect(find.text('Chọn danh mục cho slot 2'), findsOneWidget);
    expect(find.text('Đang dùng ở slot khác'), findsOneWidget);
  });

  testWidgets('the page fits a 360×640 screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
