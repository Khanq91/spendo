import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/budget/domain/budget.dart';
import 'package:spendo/features/budget/presentation/providers/budget_provider.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/home/presentation/screens/home_screen.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

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
    name: 'Thu nhập',
    colorHex: '#5A7230',
    iconName: 'work',
    isDefault: true,
    isIncome: true,
    sortOrder: 1,
  ),
];

const _wallets = [
  Wallet(
    id: 'cash',
    name: 'Tiền mặt',
    type: WalletType.cash,
    initialBalance: 1250000,
    colorHex: '#7A8A5E',
    sortOrder: 0,
    isArchived: false,
  ),
  Wallet(
    id: 'bank',
    // A long name is the realistic worst case for the chip strip.
    name: 'MB Bank tài khoản chính',
    type: WalletType.bank,
    initialBalance: 28400000,
    colorHex: '#5E7E8A',
    sortOrder: 1,
    isArchived: false,
  ),
];

List<Transaction> _transactions() {
  final now = DateTime.now();
  return [
    Transaction(
      id: 't1',
      amount: 85000,
      type: 'expense',
      categoryId: 'food',
      note: 'Ăn trưa',
      createdAt: now,
    ),
    Transaction(
      id: 't2',
      // Ten digits — the widest amount the input accepts.
      amount: 1999999999,
      type: 'income',
      categoryId: 'salary',
      note: 'Lương tháng 8 và thưởng dự án cuối năm',
      createdAt: now.subtract(const Duration(days: 1)),
      source: 'sepay',
    ),
  ];
}

void main() {
  // 360×640 is the smallest phone the app targets; the audit flagged the old
  // Home for pushing the transaction list off a screen this size.
  testWidgets('Home lays out a populated month on a 360×640 screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final month = DateTime(DateTime.now().year, DateTime.now().month);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(_transactions()),
          ),
          categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
          walletsProvider.overrideWith((ref) => Stream.value(_wallets)),
          walletBalanceProvider.overrideWith((ref, _) => Stream.value(1250000)),
          currentBudgetProvider.overrideWith(
            (ref) => Stream.value(
              Budget(
                id: 'b1',
                month: Budget.monthKey(month),
                amount: 20000000,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Every fixed block renders...
    expect(find.text('Còn lại tháng này'), findsOneWidget);
    expect(find.text('Ngân sách tháng'), findsOneWidget);
    expect(find.text('Tiền mặt'), findsOneWidget);
    // The shortcut row is Vay nợ · Sổ theo dõi · Nhắc nhở · Xem thêm. Ví and
    // Hạn mức left it because the wallet strip and the budget card above
    // already lead to those very pages.
    expect(find.text('Sổ theo dõi'), findsOneWidget);
    expect(find.text('Xem thêm'), findsOneWidget);
    expect(find.text('Gần đây'), findsOneWidget);

    // ...and the first transaction is on screen without scrolling, which is
    // the point of trimming the header blocks.
    expect(find.text('Hôm nay').hitTestable(), findsOneWidget);
    expect(find.text('Ăn uống').hitTestable(), findsOneWidget);
  });
}
