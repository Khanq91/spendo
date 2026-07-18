import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/home/presentation/screens/home_screen.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

void main() {
  testWidgets('opens reminders when the Home notification button is tapped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/reminders',
          builder: (_, __) => const Scaffold(body: Text('Reminders route')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(const <Transaction>[]),
          ),
          categoriesProvider.overrideWith(
            (ref) => Stream.value(const <Category>[]),
          ),
          walletsProvider.overrideWith((ref) => Stream.value(const <Wallet>[])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.notifications_none_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Reminders route'), findsOneWidget);
  });

  testWidgets('offers retry when the Home transaction list fails to load', (
    tester,
  ) async {
    var providerBuilds = 0;
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          walletsProvider.overrideWith((ref) => Stream.value(const <Wallet>[])),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();

    expect(find.byKey(const ValueKey('home_error')), findsOneWidget);
    expect(find.text('Không thể tải giao dịch'), findsOneWidget);
    expect(find.text('Chưa có giao dịch nào'), findsNothing);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();

    expect(providerBuilds, 2);
  });
}
