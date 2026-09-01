import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/budget/presentation/providers/category_budget_provider.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

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
    id: 'salary',
    name: 'Lương',
    colorHex: '#4CAF50',
    iconName: 'work',
    isDefault: true,
    isIncome: true,
    sortOrder: 0,
  ),
];

Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
        walletsProvider.overrideWith((ref) => Stream.value(const [])),
        categoryBudgetProgressProvider.overrideWithValue(const {}),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAddTransactionSheet(context),
              child: const Text('Mở sheet'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Mở sheet'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('keeps the save action reachable when the keyboard opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _openSheet(tester);
    expect(find.byType(SpendoNumpad), findsOneWidget);

    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();

    // The numpad yields the space to the keyboard, but Lưu — the commit
    // action — stays on screen and hittable.
    expect(find.byType(SpendoNumpad), findsNothing);
    expect(find.text('Lưu'), findsOneWidget);
    expect(find.text('Lưu').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching to Thu swaps the category grid to income ones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _openSheet(tester);

    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Lương'), findsNothing);

    await tester.tap(find.text('Thu'));
    await tester.pumpAndSettle();

    expect(find.text('Lương'), findsOneWidget);
    expect(find.text('Ăn uống'), findsNothing);
  });

  testWidgets('the amount renders a single ₫ symbol', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _openSheet(tester);

    await tester.tap(find.widgetWithText(InkWell, '5'));
    await tester.tap(find.widgetWithText(InkWell, '000'));
    await tester.pumpAndSettle();

    // Regression: the amount used to append its own '₫' next to the one
    // formatVND already adds, rendering "5.000 ₫ ₫".
    expect(find.textContaining('₫ ₫'), findsNothing);
    expect(find.text('5.000 ₫'), findsOneWidget);
  });
}
