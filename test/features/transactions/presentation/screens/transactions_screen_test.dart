import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:spendo/features/transactions/presentation/screens/transactions_screen.dart';

void main() {
  testWidgets('shows a retryable error instead of an empty transaction list', (
    tester,
  ) async {
    var providerBuilds = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith((ref) {
            providerBuilds++;
            return Stream<List<Transaction>>.error(StateError('database'));
          }),
          categoriesProvider.overrideWith(
            (ref) => Stream.value(const <Category>[]),
          ),
        ],
        child: const MaterialApp(home: TransactionsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('transactions_error')), findsOneWidget);
    expect(find.text('Không thể tải giao dịch'), findsOneWidget);
    expect(find.text('Chưa có giao dịch nào'), findsNothing);
    expect(find.text('0 giao dịch'), findsNothing);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(providerBuilds, 2);
  });
}
