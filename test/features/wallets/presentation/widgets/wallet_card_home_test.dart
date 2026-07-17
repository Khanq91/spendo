import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:spendo/features/wallets/presentation/widgets/wallet_card_home.dart';

void main() {
  testWidgets('shows a retryable error when wallets fail to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsProvider.overrideWith(
            (ref) => Stream<List<Wallet>>.error(StateError('database')),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: WalletCardHome())),
      ),
    );

    await tester.pump();

    expect(find.byKey(const ValueKey('wallets-error')), findsOneWidget);
    expect(find.text('Không thể tải nguồn tiền'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('does not auto-advance wallets when reduce motion is enabled', (
    tester,
  ) async {
    const wallets = [
      Wallet(
        id: 'cash',
        name: 'Tiền mặt',
        type: WalletType.cash,
        initialBalance: 0,
        colorHex: '#1565C0',
        sortOrder: 0,
        isArchived: false,
      ),
      Wallet(
        id: 'bank',
        name: 'Ngân hàng',
        type: WalletType.bank,
        initialBalance: 0,
        colorHex: '#2E7D32',
        sortOrder: 1,
        isArchived: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsProvider.overrideWith((ref) => Stream.value(wallets)),
          walletBalanceProvider.overrideWith((ref, _) => Stream.value(0)),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: WalletCardHome()),
          ),
        ),
      ),
    );
    await tester.pump();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller?.page, 0);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));

    expect(pageView.controller?.page, 0);
  });

  testWidgets('pauses auto-advance while the Home tab is inactive', (
    tester,
  ) async {
    const wallets = [
      Wallet(
        id: 'cash',
        name: 'Tiền mặt',
        type: WalletType.cash,
        initialBalance: 0,
        colorHex: '#1565C0',
        sortOrder: 0,
        isArchived: false,
      ),
      Wallet(
        id: 'bank',
        name: 'Ngân hàng',
        type: WalletType.bank,
        initialBalance: 0,
        colorHex: '#2E7D32',
        sortOrder: 1,
        isArchived: false,
      ),
    ];
    var isHomeActive = true;
    late StateSetter setHarnessState;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsProvider.overrideWith((ref) => Stream.value(wallets)),
          walletBalanceProvider.overrideWith((ref, _) => Stream.value(0)),
        ],
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setHarnessState = setState;
              return TickerMode(
                enabled: isHomeActive,
                child: const Scaffold(body: WalletCardHome()),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final pageController =
        tester.widget<PageView>(find.byType(PageView)).controller!;
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(pageController.page, 1);

    setHarnessState(() => isHomeActive = false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));

    expect(pageController.page, 1);
  });
}
