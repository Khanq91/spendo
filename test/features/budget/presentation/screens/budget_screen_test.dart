import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/budget/domain/budget.dart';
import 'package:spendo/features/budget/domain/category_budget.dart';
import 'package:spendo/features/budget/presentation/providers/budget_page_provider.dart';
import 'package:spendo/features/budget/presentation/providers/category_budget_provider.dart';
import 'package:spendo/features/budget/presentation/screens/budget_screen.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/shared/domain/period.dart';

const _categories = [
  Category(
    id: 'food',
    name: 'Ăn uống',
    colorHex: '#C67139',
    iconName: 'restaurant',
    isDefault: true,
    isIncome: false,
    sortOrder: 0,
  ),
  Category(
    id: 'shopping',
    name: 'Mua sắm',
    colorHex: '#B98A2F',
    iconName: 'shopping_bag',
    isDefault: true,
    isIncome: false,
    sortOrder: 1,
  ),
  Category(
    id: 'transport',
    name: 'Di chuyển',
    colorHex: '#7A8A5E',
    iconName: 'directions_car',
    isDefault: true,
    isIncome: false,
    sortOrder: 2,
  ),
];

Transaction _expense(String categoryId, int amount) => Transaction(
  id: 'tx_${categoryId}_$amount',
  amount: amount,
  type: 'expense',
  categoryId: categoryId,
  createdAt: DateTime(2026, 8, 10),
  walletId: null,
  source: 'manual',
);

ProviderContainer _container({
  int? monthBudget = 20000000,
  List<CategoryBudget> categoryBudgets = const [
    CategoryBudget(id: 'b1', categoryId: 'food', amount: 3000000),
    CategoryBudget(id: 'b2', categoryId: 'shopping', amount: 1500000),
  ],
  List<Transaction> transactions = const [],
}) {
  return ProviderContainer(
    overrides: [
      budgetPeriodProvider.overrideWith(
        (ref) => Period.month(DateTime(2026, 8)),
      ),
      budgetPageBudgetProvider.overrideWith(
        (ref) => Stream.value(
          monthBudget == null
              ? null
              : Budget(id: 'm', amount: monthBudget, month: '2026-08'),
        ),
      ),
      budgetPeriodTransactionsProvider.overrideWith(
        (ref) => Stream.value(transactions),
      ),
      categoryBudgetsProvider.overrideWith((ref) => Stream.value(categoryBudgets)),
      categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
    ],
  );
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        home: const BudgetScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('the month total and the category limits share one page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = _container(
      transactions: [_expense('food', 2550000), _expense('shopping', 1800000)],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The three sheets the audit found — a chooser, a month sheet and a
    // category list — are one page, so both limits are visible at once.
    expect(find.text('Tổng tháng'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Mua sắm'), findsOneWidget);
    // 4.350.000 of 20.000.000.
    expect(find.text('22%'), findsOneWidget);
  });

  testWidgets('spending past a category limit reads as over, not as 100%', (
    tester,
  ) async {
    final container = _container(
      transactions: [_expense('shopping', 1800000)],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Vượt +300.000 ₫'), findsOneWidget);
  });

  testWidgets('a category with no limit is offered as a chip', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Chưa đặt hạn mức'), findsOneWidget);
    expect(find.text('Di chuyển'), findsOneWidget);
  });

  testWidgets('with no month limit the page still shows what was spent', (
    tester,
  ) async {
    final container = _container(
      monthBudget: null,
      transactions: [_expense('food', 2550000)],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    // The old sheet asked for a limit without ever saying what had been spent.
    expect(find.text('Chưa đặt hạn mức · đã chi 2.550.000 ₫'), findsOneWidget);
    expect(find.text('Đặt hạn mức tháng'), findsOneWidget);
  });

  testWidgets('the page has its own period, separate from Home', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Hạn mức'), findsOneWidget);
    expect(find.text(Period.month(DateTime(2026, 8)).shortLabel()), findsOneWidget);
  });
}
