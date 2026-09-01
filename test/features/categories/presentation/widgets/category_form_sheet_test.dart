import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

const _existing = Category(
  id: 'food',
  name: 'Ăn uống',
  colorHex: '#FF6B6B',
  iconName: 'restaurant',
  isDefault: false,
  isIncome: false,
  sortOrder: 0,
);

Widget _app(Widget sheet) {
  return MaterialApp(
    theme: AppTheme.light(AppColorScheme.roseDefault),
    home: Scaffold(body: sheet),
  );
}

void main() {
  testWidgets('the title says which side the category belongs to', (
    tester,
  ) async {
    // The old sheet said only "Thêm danh mục" whichever tab opened it
    // (`21-category-form-sheet.md` §L).
    await tester.pumpWidget(_app(const CategoryFormSheet(isIncome: false)));
    await tester.pumpAndSettle();
    expect(find.text('Thêm danh mục chi'), findsOneWidget);

    await tester.pumpWidget(_app(const CategoryFormSheet(isIncome: true)));
    await tester.pumpAndSettle();
    expect(find.text('Thêm danh mục thu'), findsOneWidget);

    await tester.pumpWidget(
      _app(const CategoryFormSheet(existing: _existing, isIncome: false)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sửa danh mục chi'), findsOneWidget);
  });

  testWidgets('an empty name fails inline instead of silently', (tester) async {
    await tester.pumpWidget(_app(const CategoryFormSheet(isIncome: false)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Đặt tên cho danh mục này'), findsOneWidget);

    // Typing clears it again rather than leaving a stale error.
    await tester.enterText(find.byType(TextField), 'Thú cưng');
    await tester.pumpAndSettle();
    expect(find.text('Đặt tên cho danh mục này'), findsNothing);
  });

  testWidgets('the form scrolls, so the keyboard cannot bury the name field', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(const CategoryFormSheet(existing: _existing, isIncome: false)),
    );
    await tester.pumpAndSettle();

    // The old sheet was a plain Column ~470px tall plus a ~300px keyboard
    // (`21-category-form-sheet.md` §E).
    expect(find.byType(ListView), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('it is built on the shared sheet, so it gets the drag handle', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const CategoryFormSheet(isIncome: false)));
    await tester.pumpAndSettle();

    expect(find.byType(SpendoSheet), findsOneWidget);
    expect(find.byType(SpendoDragHandle), findsOneWidget);
    expect(find.text('Huỷ'), findsOneWidget);
  });
}
