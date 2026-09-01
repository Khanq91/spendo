import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:spendo/features/budget/domain/budget.dart';
import 'package:spendo/features/budget/presentation/providers/budget_provider.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/home/presentation/screens/home_screen.dart';
import 'package:spendo/features/transactions/domain/transaction.dart';
import 'package:spendo/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:spendo/shared/providers/shell_tab_provider.dart';

List<Override> _baseOverrides({
  Stream<List<Transaction>>? transactions,
  Stream<List<Wallet>>? wallets,
  Stream<Budget?>? budget,
}) {
  return [
    transactionsProvider.overrideWith(
      (ref) => transactions ?? Stream.value(const <Transaction>[]),
    ),
    categoriesProvider.overrideWith(
      (ref) => Stream.value(const <Category>[]),
    ),
    walletsProvider.overrideWith(
      (ref) => wallets ?? Stream.value(const <Wallet>[]),
    ),
    currentBudgetProvider.overrideWith((ref) => budget ?? Stream.value(null)),
  ];
}

void main() {
  testWidgets('opens reminders when the Home notification button is tapped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
        overrides: _baseOverrides(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(LucideIcons.bell));
    await tester.pumpAndSettle();

    expect(find.text('Reminders route'), findsOneWidget);
  });

  testWidgets('offers retry when the Home transaction list fails to load', (
    tester,
  ) async {
    var providerBuilds = 0;
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
          currentBudgetProvider.overrideWith((ref) => Stream.value(null)),
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

  testWidgets('shows the dashed CTA until a budget exists, then progress', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final month = DateTime(DateTime.now().year, DateTime.now().month);
    final budgets = StreamController<Budget?>();
    addTearDown(budgets.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(budget: budgets.stream),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    budgets.add(null);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home_budget_cta')), findsOneWidget);
    expect(find.text('Đặt hạn mức cho tháng này'), findsOneWidget);
    expect(find.byKey(const ValueKey('home_budget_progress')), findsNothing);

    budgets.add(
      Budget(id: 'b1', month: Budget.monthKey(month), amount: 1000000),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home_budget_progress')), findsOneWidget);
    expect(find.text('Ngân sách tháng'), findsOneWidget);
    expect(find.byKey(const ValueKey('home_budget_cta')), findsNothing);
  });

  testWidgets('the eye masks every amount in the header at once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(
          transactions: Stream.value([
            Transaction(
              id: 't1',
              amount: 30000,
              type: 'expense',
              categoryId: 'food',
              createdAt: DateTime.now(),
            ),
          ]),
        ),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Amounts start visible — the audit's three separate eyes all defaulted
    // to hidden, so every launch needed three taps to read the numbers.
    expect(find.text('••••••'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home_balance_eye')));
    await tester.pumpAndSettle();

    // Balance plus both components.
    expect(find.text('••••••'), findsNWidgets(3));
  });

  testWidgets('"Xem tất cả" moves the shell to the transactions tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: _baseOverrides());
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(container.read(shellTabProvider), ShellTab.home);

    await tester.tap(find.byKey(const ValueKey('home_see_all')));
    await tester.pump();

    expect(container.read(shellTabProvider), ShellTab.transactions);
  });
}
