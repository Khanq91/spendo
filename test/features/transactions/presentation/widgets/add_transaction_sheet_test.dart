import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/budget/presentation/providers/category_budget_provider.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/presentation/widgets/add_transaction_sheet.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
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

  testWidgets('opened as Thu, the sheet starts on the income grid', (
    tester,
  ) async {
    // A duplicated salary used to open on Chi, lose its category to the
    // expense grid and come out as an "Ăn uống" expense.
    await _openSheetWith(
      tester,
      initialIsExpense: false,
      preselectedCategoryId: 'salary',
    );

    expect(find.text('Lương'), findsOneWidget);
    expect(find.text('Ăn uống'), findsNothing);
  });

  testWidgets('a new entry defaults to the wallet the last one went into', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'last_wallet_id': 'bank'});

    await _openSheetWith(tester, wallets: _wallets);

    expect(find.text('MB Bank'), findsOneWidget);
    expect(find.text('Chọn ví'), findsNothing);
  });

  testWidgets('an archived wallet does not come back as the default', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'last_wallet_id': 'old'});

    await _openSheetWith(tester, wallets: _wallets);

    expect(find.text('Chọn ví'), findsOneWidget);
  });

  testWidgets('a wallet chosen by the caller beats the remembered one', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'last_wallet_id': 'bank'});

    await _openSheetWith(
      tester,
      wallets: _wallets,
      preselectedWalletId: 'cash',
    );

    expect(find.text('Tiền mặt'), findsOneWidget);
    expect(find.text('MB Bank'), findsNothing);
  });

  testWidgets('Lưu & thêm tiếp is offered for new entries only', (
    tester,
  ) async {
    await _openSheetWith(tester);
    expect(find.byKey(const ValueKey('add_save_more')), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);

    await _openSheetWith(
      tester,
      existing: Transaction(
        id: 't1',
        amount: 50000,
        type: 'expense',
        categoryId: 'food',
        createdAt: DateTime(2026, 9, 1, 12),
      ),
    );
    expect(find.byKey(const ValueKey('add_save_more')), findsNothing);
  });
}

const _wallets = [
  Wallet(
    id: 'bank',
    name: 'MB Bank',
    type: WalletType.bank,
    initialBalance: 0,
    note: null,
    colorHex: '#5E7E8A',
    sortOrder: 0,
    isArchived: false,
  ),
  Wallet(
    id: 'cash',
    name: 'Tiền mặt',
    type: WalletType.cash,
    initialBalance: 0,
    note: null,
    colorHex: '#C67139',
    sortOrder: 1,
    isArchived: false,
  ),
  Wallet(
    id: 'old',
    name: 'Ví cũ',
    type: WalletType.cash,
    initialBalance: 0,
    note: null,
    colorHex: '#999999',
    sortOrder: 2,
    isArchived: true,
  ),
];

Future<void> _openSheetWith(
  WidgetTester tester, {
  List<Wallet> wallets = const [],
  bool? initialIsExpense,
  String? preselectedCategoryId,
  String? preselectedWalletId,
  Transaction? existing,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
        walletsProvider.overrideWith((ref) => Stream.value(wallets)),
        categoryBudgetProgressProvider.overrideWithValue(const {}),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAddTransactionSheet(
                context,
                existing: existing,
                initialIsExpense: initialIsExpense,
                preselectedCategoryId: preselectedCategoryId,
                preselectedWalletId: preselectedWalletId,
              ),
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
