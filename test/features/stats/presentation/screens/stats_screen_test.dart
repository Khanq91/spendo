import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/stats/presentation/providers/stats_provider.dart';
import 'package:spendo/features/stats/presentation/screens/stats_screen.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';

void main() {
  testWidgets('renders animated summary, pie chart, and daily bar chart', (
    tester,
  ) async {
    final now = DateTime.now();
    final transactions = [
      Transaction(
        id: 'expense',
        amount: 120000,
        type: 'expense',
        categoryId: 'food',
        createdAt: now,
      ),
      Transaction(
        id: 'income',
        amount: 200000,
        type: 'income',
        categoryId: 'salary',
        createdAt: now,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsTransactionsProvider.overrideWith(
            (ref) => Stream.value(transactions),
          ),
          categoriesProvider.overrideWith(
            (ref) => Stream.value(const [
              Category(
                id: 'food',
                name: 'Ăn uống',
                colorHex: '#FF7043',
                iconName: 'utensils',
                isDefault: true,
                isIncome: false,
                sortOrder: 0,
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Chi'), findsOneWidget);
    expect(find.text('Ròng'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);

    await tester.tap(find.text('Theo ngày'));
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
  });
}
