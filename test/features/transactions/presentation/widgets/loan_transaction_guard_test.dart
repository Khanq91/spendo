import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/loan/data/loan_repository.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/presentation/widgets/grouped_transaction_sliver.dart';
import 'package:spendo/features/transactions/presentation/widgets/transaction_detail_sheet.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

const _repay = Category(
  id: 'loan-repay',
  name: 'Trả nợ',
  colorHex: '#B0BEC5',
  iconName: 'loan_repay',
  isDefault: true,
  isIncome: false,
  sortOrder: 7,
);

const _wallet = Wallet(
  id: 'bank',
  name: 'MB Bank',
  type: WalletType.bank,
  initialBalance: 0,
  colorHex: '#5E7E8A',
  sortOrder: 0,
  isArchived: false,
);

Transaction _transaction({String source = kLoanTransactionSource}) =>
    Transaction(
      id: 't1',
      amount: 2000000,
      type: 'expense',
      categoryId: 'loan-repay',
      note: 'Trả nợ: Vay mua xe',
      createdAt: DateTime(2026, 10, 16),
      walletId: 'bank',
      source: source,
    );

Future<void> _pumpDetail(WidgetTester tester, Transaction transaction) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        walletsProvider.overrideWith((ref) => Stream.value(const [_wallet])),
      ],
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        home: Scaffold(
          body: TransactionDetailSheet(
            transaction: transaction,
            category: _repay,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpList(WidgetTester tester, Transaction transaction) async {
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
                transactions: [transaction],
                categoryMap: const {'loan-repay': _repay},
                dismissible: true,
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
  testWidgets('a loan transaction says where it came from', (tester) async {
    await _pumpDetail(tester, _transaction());

    // The loan itself cannot be looked up without a database, so the banner
    // falls back to the general wording rather than breaking.
    expect(
      find.textContaining('thuộc'),
      findsOneWidget,
    );
    expect(find.text('Mở khoản vay'), findsOneWidget);
  });

  testWidgets('a loan transaction offers no edit, delete or duplicate', (
    tester,
  ) async {
    await _pumpDetail(tester, _transaction());

    // One direction of truth: the loan owns the money, so the transaction is
    // changed by changing the loan (PLAN §2.9).
    expect(find.text('Chỉnh sửa'), findsNothing);
    expect(find.text('Nhân bản'), findsNothing);
    expect(find.bySemanticsLabel('Xoá giao dịch'), findsNothing);
  });

  testWidgets('the date of a loan transaction is not editable either', (
    tester,
  ) async {
    await _pumpDetail(tester, _transaction());

    // The date row loses its pencil and its tap target when there is nothing
    // it may change.
    expect(find.bySemanticsLabel('Sửa Ngày'), findsNothing);
  });

  testWidgets('an ordinary transaction keeps every action', (tester) async {
    await _pumpDetail(tester, _transaction(source: 'manual'));

    expect(find.text('Chỉnh sửa'), findsOneWidget);
    expect(find.text('Nhân bản'), findsOneWidget);
    expect(find.textContaining('thuộc khoản vay'), findsNothing);
  });

  testWidgets('swiping a loan transaction says no instead of removing it', (
    tester,
  ) async {
    await _pumpList(tester, _transaction());

    // The row is titled by its category; the note rides in the subtitle.
    await tester.drag(find.text('Trả nợ').last, const Offset(-400, 0));
    await tester.pumpAndSettle();

    // The row springs back and the snackbar explains why, rather than the row
    // vanishing and reappearing on the next stream emit.
    expect(find.textContaining('Trả nợ: Vay mua xe'), findsOneWidget);
    expect(
      find.text('Giao dịch của khoản vay — xoá từ màn khoản vay.'),
      findsOneWidget,
    );
  });
}
