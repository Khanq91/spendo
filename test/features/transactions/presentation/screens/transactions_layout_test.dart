import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:spendo/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

const _categories = [
  Category(
    id: 'salary',
    name: 'Thu nhập',
    colorHex: '#5A7230',
    iconName: 'work',
    isDefault: true,
    isIncome: true,
    sortOrder: 0,
  ),
];

const _wallets = [
  Wallet(
    id: 'bank',
    name: 'MB Bank tài khoản chính',
    type: WalletType.bank,
    initialBalance: 0,
    colorHex: '#5E7E8A',
    sortOrder: 0,
    isArchived: false,
  ),
];

void main() {
  // 360×640 is the smallest phone the app targets. The control row packs a
  // period stepper, a three-option segmented and the filter button into one
  // line, so it is the tightest row in the app.
  testWidgets('the transaction screen fits a 360×640 screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        periodTransactionsProvider.overrideWith(
          (ref) => Stream.value([
            Transaction(
              id: 't1',
              // Ten digits, the widest amount the input accepts.
              amount: 1999999999,
              type: 'income',
              categoryId: 'salary',
              note: 'Lương tháng 8 và thưởng dự án cuối năm',
              createdAt: DateTime.now(),
              walletId: 'bank',
              source: 'sepay',
            ),
          ]),
        ),
        categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
        walletsProvider.overrideWith((ref) => Stream.value(_wallets)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(AppColorScheme.roseDefault),
          home: const TransactionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Giao dịch'), findsOneWidget);
    expect(find.text('Chi'), findsOneWidget);
    expect(find.text('Thu nhập'), findsOneWidget);
  });

  testWidgets('applied filter chips do not overflow the row', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        periodTransactionsProvider.overrideWith(
          (ref) => Stream.value(const <Transaction>[]),
        ),
        categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
        walletsProvider.overrideWith((ref) => Stream.value(_wallets)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(AppColorScheme.roseDefault),
          home: const TransactionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Several filters at once — the chips scroll rather than overflow.
    container.read(transactionFilterProvider.notifier).state = container
        .read(transactionFilterProvider)
        .toggleCategory('salary')
        .toggleWallet('bank');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('MB Bank tài khoản chính'), findsOneWidget);
  });
}
