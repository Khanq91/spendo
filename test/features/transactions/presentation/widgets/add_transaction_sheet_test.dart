import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/budget/presentation/providers/category_budget_provider.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:spendo/features/transactions/presentation/widgets/numpad.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

void main() {
  testWidgets('keeps the transaction CTA reachable when the keyboard opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const categories = [
      Category(
        id: 'food',
        name: 'Ăn uống',
        colorHex: '#FF6B6B',
        iconName: 'utensils',
        isDefault: true,
        isIncome: false,
        sortOrder: 0,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) => Stream.value(categories)),
          walletsProvider.overrideWith((ref) => Stream.value(const [])),
          categoryBudgetProgressProvider.overrideWithValue(const {}),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const AddTransactionSheet(),
                      );
                    },
                    child: const Text('Thêm giao dịch'),
                  ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Thêm giao dịch'));
    await tester.pumpAndSettle();
    expect(find.byType(Numpad), findsOneWidget);

    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();

    expect(find.byType(Numpad), findsNothing);
    expect(find.textContaining('Chi 0'), findsOneWidget);
    expect(find.textContaining('Chi 0').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
