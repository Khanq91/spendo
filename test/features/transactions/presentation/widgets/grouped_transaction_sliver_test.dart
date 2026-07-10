import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/presentation/widgets/grouped_transaction_sliver.dart';
import 'package:spendo/features/transactions/presentation/widgets/transaction_list_item.dart';

void main() {
  testWidgets('uses stable keys and lazily builds a large transaction list', (
    tester,
  ) async {
    final transactions = List.generate(
      500,
      (index) => Transaction(
        id: 'tx_$index',
        amount: 1000 + index,
        type: index.isEven ? 'expense' : 'income',
        categoryId: 'category',
        createdAt: DateTime(2026, 7, 10, 12, index % 60),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GroupedTransactionSliver(
                  transactions: transactions,
                  categoryMap: const {},
                  animateItems: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('day_20260710')), findsOneWidget);
    expect(find.byKey(const ValueKey('tx_0')), findsOneWidget);
    expect(find.byType(TransactionListItem), findsWidgets);
    expect(
      find.byType(TransactionListItem).evaluate().length,
      lessThan(transactions.length),
    );
  });
}
