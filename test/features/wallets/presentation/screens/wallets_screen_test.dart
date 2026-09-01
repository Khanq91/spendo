import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:spendo/features/wallets/presentation/screens/wallets_screen.dart';

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
    id: 'credit',
    // Long enough to compete with the amount for the row's width.
    name: 'Thẻ tín dụng VIB Cashback Platinum',
    type: WalletType.credit,
    initialBalance: 0,
    colorHex: '#A5668B',
    sortOrder: 1,
    isArchived: false,
  ),
];

const _archived = [
  Wallet(
    id: 'old',
    name: 'Ví cũ',
    type: WalletType.ewallet,
    initialBalance: 0,
    colorHex: '#5E7E8A',
    sortOrder: 2,
    isArchived: true,
  ),
];

ProviderContainer _container({
  List<Wallet> wallets = _wallets,
  List<Wallet> archived = const [],
  int balance = 1250000,
}) {
  return ProviderContainer(
    overrides: [
      walletsProvider.overrideWith((ref) => Stream.value(wallets)),
      archivedWalletsProvider.overrideWith((ref) => Stream.value(archived)),
      totalNetWorthProvider.overrideWith((ref) => Stream.value(balance)),
      totalWalletBreakdownProvider.overrideWith(
        (ref) => Stream.value((x1: 41900000, x2: 13750000)),
      ),
      walletBalanceProvider.overrideWith((ref, id) {
        return Stream.value(id == 'credit' ? -1999999999 : balance);
      }),
    ],
  );
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        home: const WalletsScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('the wallet list fits a 360×640 screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = _container(archived: _archived);
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Nguồn tiền'), findsOneWidget);
    // A ten-digit negative balance beside a long wallet name is the tightest
    // row this screen produces.
    expect(find.text('Đang âm'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ĐÃ LƯU TRỮ (1)'), 120);
    expect(find.text('ĐÃ LƯU TRỮ (1)'), findsOneWidget);
  });

  testWidgets('there is one way to add a wallet, not three', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    // The audit counted three "Thêm nguồn tiền" affordances on this screen
    // (app-bar +, a button under the list, and the empty-state CTA).
    expect(find.text('Thêm nguồn tiền'), findsOneWidget);
  });

  testWidgets('an empty list offers the add action once', (tester) async {
    final container = _container(wallets: const [], balance: 0);
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Chưa có nguồn tiền nào'), findsOneWidget);
    // The empty state names the action and the FAB carries it — one label
    // each, from the same string.
    expect(find.text('Thêm nguồn tiền'), findsNWidgets(2));
  });

  testWidgets('a failed load offers a retry instead of a raw exception', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        walletsProvider.overrideWith(
          (ref) => Stream<List<Wallet>>.error(StateError('db down')),
        ),
        archivedWalletsProvider.overrideWith((ref) => Stream.value(const [])),
        totalNetWorthProvider.overrideWith((ref) => Stream.value(0)),
        totalWalletBreakdownProvider.overrideWith(
          (ref) => Stream.value((x1: 0, x2: 0)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pump(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Không tải được nguồn tiền'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.textContaining('db down'), findsNothing);
  });
}
