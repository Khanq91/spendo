import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/settings/presentation/screens/widget_screen.dart';

const _food = Category(
  id: 'food',
  name: 'Ăn uống',
  colorHex: '#FF6B6B',
  iconName: 'restaurant',
  isDefault: true,
  isIncome: false,
  sortOrder: 0,
);
const _car = Category(
  id: 'car',
  name: 'Di chuyển',
  colorHex: '#7A8A5E',
  iconName: 'directions_car',
  isDefault: true,
  isIncome: false,
  sortOrder: 1,
);
const _fun = Category(
  id: 'fun',
  name: 'Giải trí',
  colorHex: '#A5668B',
  iconName: 'movie',
  isDefault: false,
  isIncome: false,
  sortOrder: 2,
);
const _shop = Category(
  id: 'shop',
  name: 'Mua sắm',
  colorHex: '#B98A2F',
  iconName: 'shopping_bag',
  isDefault: false,
  isIncome: false,
  sortOrder: 3,
);
const _study = Category(
  id: 'study',
  name: 'Học tập',
  colorHex: '#5E7E8A',
  iconName: 'school',
  isDefault: false,
  isIncome: false,
  sortOrder: 4,
);

const _five = [_food, _car, _fun, _shop, _study];

Widget _app({List<Category> categories = _five}) {
  return ProviderScope(
    overrides: [
      categoriesProvider.overrideWith((ref) => Stream.value(categories)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      home: const WidgetScreen(),
    ),
  );
}

void main() {
  testWidgets('all four slots hold a category and none can be cleared', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (var i = 1; i <= 4; i++) {
      expect(find.text('Slot $i'), findsOneWidget);
    }

    // Nothing was ever pinned, so the first four categories fill the slots.
    // Each name appears twice: once in the preview, once in its row.
    for (final name in ['Ăn uống', 'Di chuyển', 'Giải trí', 'Mua sắm']) {
      expect(find.text(name), findsNWidgets(2), reason: name);
    }
    // The fifth is simply not shown.
    expect(find.text('Học tập'), findsNothing);

    // Every slot always holds something, so there is nothing to unpin.
    expect(find.text('Bỏ ghim'), findsNothing);
    expect(find.text('Chưa đủ danh mục'), findsNothing);
  });

  testWidgets('a pinned slot wins over the default order', (tester) async {
    SharedPreferences.setMockInitialValues({
      'widget_pinned_ids': '["study","","",""]',
    });

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Slot 1 is the pinned one; the rest fall back to unused categories in
    // order, so the pinned category is never also served as a fallback.
    expect(find.text('Học tập'), findsNWidgets(2));
    expect(find.text('Mua sắm'), findsNothing);
  });

  testWidgets('with fewer than four categories the spare slots say so', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app(categories: const [_food, _car]));
    await tester.pumpAndSettle();

    // The old build silently showed four hard-coded names here.
    expect(find.text('Chưa đủ danh mục'), findsNWidgets(2));
    expect(find.text('Ô này mở Thêm giao dịch để trống'), findsNWidgets(2));
    expect(find.text('Ghi nhanh'), findsNWidgets(2));
  });

  testWidgets('tapping a slot offers a swap, greying out the ones in use', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Slot 1'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn danh mục cho slot 1'), findsOneWidget);
    // Slots 2–4 hold three categories; those cannot be picked again here.
    expect(find.text('Đang dùng ở slot khác'), findsNWidgets(3));
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
