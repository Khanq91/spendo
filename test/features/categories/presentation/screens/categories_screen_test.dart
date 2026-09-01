import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/categories/presentation/screens/categories_screen.dart';

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
    id: 'fun',
    name: 'Giải trí',
    colorHex: '#A5668B',
    iconName: 'movie',
    isDefault: false,
    isIncome: false,
    sortOrder: 1,
  ),
  Category(
    id: 'unused',
    name: 'Thú cưng',
    colorHex: '#96CEB4',
    iconName: 'pets',
    isDefault: false,
    isIncome: false,
    sortOrder: 2,
  ),
  Category(
    id: 'salary',
    name: 'Lương',
    colorHex: '#96CEB4',
    iconName: 'work',
    isDefault: true,
    isIncome: true,
    sortOrder: 0,
  ),
];

const _counts = {'food': 46, 'fun': 3};

Widget _app({
  List<Category> categories = _categories,
  Map<String, int> counts = _counts,
}) {
  return ProviderScope(
    overrides: [
      categoriesProvider.overrideWith((ref) => Stream.value(categories)),
      categoryTransactionCountsProvider.overrideWith(
        (ref) => Stream.value(counts),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      home: const CategoriesScreen(),
    ),
  );
}

void main() {
  testWidgets('the segmented control splits Chi and Thu with live counts', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('Chi (3)'), findsOneWidget);
    expect(find.text('Thu (1)'), findsOneWidget);

    // Expense side is the default, so income categories stay hidden.
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Lương'), findsNothing);

    await tester.tap(find.text('Thu (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Lương'), findsOneWidget);
    expect(find.text('Ăn uống'), findsNothing);
  });

  testWidgets('each row states what it holds before you try to delete it', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    // The old list showed only "Mặc định" and let the delete fail afterwards
    // with an exception string (`20-settings.md` §D row 9).
    expect(find.text('Mặc định · 46 giao dịch'), findsOneWidget);
    expect(find.text('3 giao dịch'), findsOneWidget);
    expect(find.text('Chưa dùng'), findsOneWidget);
  });

  testWidgets('only a deletable category is swipeable', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    Finder dismissibleFor(String name) => find.ancestor(
      of: find.text(name),
      matching: find.byType(Dismissible),
    );

    // A default category and one still holding transactions cannot be
    // deleted, so neither arms the gesture.
    expect(dismissibleFor('Ăn uống'), findsNothing);
    expect(dismissibleFor('Giải trí'), findsNothing);
    expect(dismissibleFor('Thú cưng'), findsOneWidget);
  });

  testWidgets('an empty side offers the way out instead of a blank list', (
    tester,
  ) async {
    await tester.pumpWidget(_app(categories: const [], counts: const {}));
    await tester.pump();

    expect(find.text('Chưa có danh mục chi nào'), findsOneWidget);
    expect(find.text('Thêm danh mục'), findsWidgets);
  });

  testWidgets('the list fits a 360×640 screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
