import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/stats/presentation/providers/stats_provider.dart';
import 'package:spendo/features/stats/presentation/screens/stats_screen.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/domain/transaction_filter.dart';
import 'package:spendo/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:spendo/shared/domain/period.dart';
import 'package:spendo/shared/providers/shell_tab_provider.dart';

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
    id: 'salary',
    name: 'Lương',
    colorHex: '#5A7230',
    iconName: 'work',
    isDefault: true,
    isIncome: true,
    sortOrder: 1,
  ),
];

Transaction _tx(String id, int amount, String type, String categoryId) =>
    Transaction(
      id: id,
      amount: amount,
      type: type,
      categoryId: categoryId,
      createdAt: DateTime(2026, 8, 10),
    );

ProviderContainer _container({List<Transaction>? transactions}) {
  return ProviderContainer(
    overrides: [
      statsPeriodProvider.overrideWith((ref) => Period.month(DateTime(2026, 8))),
      statsTransactionsProvider.overrideWith(
        (ref) => Stream.value(
          transactions ??
              [
                _tx('e1', 120000, 'expense', 'food'),
                _tx('i1', 200000, 'income', 'salary'),
              ],
        ),
      ),
      categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
    ],
  );
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        home: const StatsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the summary, the pie and the legend fit one screen', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(tester.takeException(), isNull);
    expect(find.text('Thu'), findsWidgets);
    expect(find.text('Ròng'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
  });

  testWidgets('switching to Thu breaks down income, not expense', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    // The audit found Stats hard-wired to expense — the pie ignored income
    // entirely, so a month of only salary read as "Chưa có dữ liệu".
    expect(find.text('Tổng chi'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);

    await tester.tap(find.widgetWithText(GestureDetector, 'Thu').last);
    await tester.pumpAndSettle();

    expect(find.text('Tổng thu'), findsOneWidget);
    expect(find.text('Lương'), findsOneWidget);
    expect(find.text('Ăn uống'), findsNothing);
  });

  testWidgets('a month with only income still has a breakdown', (tester) async {
    final container = _container(
      transactions: [_tx('i1', 200000, 'income', 'salary')],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);

    // Expense side is genuinely empty and says so.
    expect(find.text('Chưa có khoản chi nào trong kỳ này'), findsOneWidget);

    await tester.tap(find.widgetWithText(GestureDetector, 'Thu').last);
    await tester.pumpAndSettle();

    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('Lương'), findsOneWidget);
  });

  testWidgets('tapping a legend row opens the filtered transaction list', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    await tester.tap(find.text('Ăn uống'));
    await tester.pumpAndSettle();

    // Drill-down (`04 …dc.html` §note 1): the legend used to be inert, so a
    // 44% slice gave no way through to the entries behind it.
    expect(container.read(shellTabProvider), ShellTab.transactions);
    expect(
      container.read(transactionsPeriodProvider),
      Period.month(DateTime(2026, 8)),
    );
    final filter = container.read(transactionFilterProvider);
    expect(filter.categoryIds, {'food'});
    expect(filter.type, TransactionTypeFilter.expense);
  });

  testWidgets('the daily view draws bars and a per-day table', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);

    await tester.tap(find.widgetWithText(GestureDetector, 'Theo ngày'));
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('CHI TIẾT TỪNG NGÀY'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry, not an empty chart', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        statsPeriodProvider.overrideWith(
          (ref) => Period.month(DateTime(2026, 8)),
        ),
        statsTransactionsProvider.overrideWith(
          (ref) => Stream<List<Transaction>>.error(StateError('db down')),
        ),
        categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);

    expect(find.text('Không tải được thống kê'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('db down'), findsNothing);
  });
}
