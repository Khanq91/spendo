import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/presentation/widgets/grouped_transaction_sliver.dart';

const _categoryMap = {
  'food': Category(
    id: 'food',
    name: 'Ăn uống',
    colorHex: '#C67139',
    iconName: 'restaurant',
    isDefault: true,
    isIncome: false,
    sortOrder: 0,
  ),
};

Future<void> _pump(WidgetTester tester, {required bool dismissible}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              GroupedTransactionSliver(
                transactions: [
                  Transaction(
                    id: 't1',
                    amount: 65000,
                    type: 'expense',
                    categoryId: 'food',
                    note: 'Trà sữa',
                    createdAt: DateTime.now(),
                  ),
                ],
                categoryMap: _categoryMap,
                dismissible: dismissible,
                animateItems: false,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('rows are not swipeable by default', (tester) async {
    // Home shows the list as a summary, not as the place to manage entries.
    await _pump(tester, dismissible: false);

    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets('the transaction list swipes a row away without confirming', (
    tester,
  ) async {
    await _pump(tester, dismissible: true);

    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);

    await tester.drag(find.byType(Dismissible), const Offset(-400, 0));
    await tester.pumpAndSettle();

    // The row goes on the swipe — no confirm dialog stands in the way. The
    // repository call and its undo snackbar need a live database, so they are
    // out of reach here; `deleteTransactionWithUndo` owns that half.
    expect(find.text('Ăn uống'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
