import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:spendo/features/wallets/presentation/screens/wallet_detail_screen.dart';

const _wallet = Wallet(
  id: 'bank',
  name: 'MB Bank',
  type: WalletType.bank,
  initialBalance: 12000000,
  note: 'Tài khoản lương',
  colorHex: '#5E7E8A',
  sortOrder: 0,
  isArchived: false,
);

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
];

ProviderContainer _container({
  List<Wallet>? wallets,
  List<Transaction> transactions = const [],
}) {
  return ProviderContainer(
    overrides: [
      walletsProvider.overrideWith(
        (ref) => Stream.value(wallets ?? const [_wallet]),
      ),
      archivedWalletsProvider.overrideWith((ref) => Stream.value(const [])),
      walletBalanceProvider.overrideWith((ref, id) => Stream.value(28400000)),
      walletBreakdownProvider.overrideWith(
        (ref, id) => Stream.value((x1: 30000000, x2: 1600000)),
      ),
      walletTxByMonthProvider.overrideWith(
        (ref, args) => Stream.value(transactions),
      ),
      walletTxAllProvider.overrideWith((ref, id) => Stream.value(transactions)),
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
        home: const WalletDetailScreen(walletId: 'bank'),
      ),
    ),
  );
}

void main() {
  testWidgets('the wallet header, scope bar and list fit a 360×640 screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = _container(
      transactions: [
        Transaction(
          id: 't1',
          amount: 85000,
          type: 'expense',
          categoryId: 'food',
          note: 'Ăn trưa',
          createdAt: DateTime.now(),
          walletId: 'bank',
          source: 'manual',
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('MB Bank'), findsNWidgets(2)); // header + card
    expect(find.text('Ngân hàng · Tài khoản lương'), findsOneWidget);
    // The screen the audit found had no way to add a transaction to the very
    // wallet you were looking at.
    expect(find.text('Thêm giao dịch'), findsOneWidget);
  });

  testWidgets('a wallet that no longer exists says so instead of spinning', (
    tester,
  ) async {
    // Both the loading and the deleted case used to hit the same branch, so a
    // wallet removed elsewhere left an endless spinner with no explanation.
    final container = _container(wallets: const []);
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Nguồn tiền không còn tồn tại'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('an empty month names the period rather than the whole history', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Không có giao dịch trong kỳ này'), findsOneWidget);

    await tester.tap(find.text('Tất cả'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có giao dịch nào'), findsOneWidget);
  });
}
