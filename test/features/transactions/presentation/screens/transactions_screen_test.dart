import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    name: 'Lương',
    colorHex: '#5A7230',
    iconName: 'work',
    isDefault: true,
    isIncome: true,
    sortOrder: 1,
  ),
];

List<Transaction> _sample() {
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
      amount: 18000000,
      type: 'income',
      categoryId: 'salary',
      note: 'Lương tháng 8',
      createdAt: now,
    ),
  ];
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Stream<List<Transaction>>? transactions,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      periodTransactionsProvider.overrideWith(
        (ref) => transactions ?? Stream.value(_sample()),
      ),
      categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
      walletsProvider.overrideWith((ref) => Stream.value(const <Wallet>[])),
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
  // The skeleton pulses forever, so a settling pump would time out while the
  // stream has not emitted yet.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return container;
}

void main() {
  testWidgets('shows a retryable error instead of an empty transaction list', (
    tester,
  ) async {
    var providerBuilds = 0;
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        periodTransactionsProvider.overrideWith((ref) {
          providerBuilds++;
          return Stream<List<Transaction>>.error(StateError('database'));
        }),
        categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
        walletsProvider.overrideWith((ref) => Stream.value(const <Wallet>[])),
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

    expect(find.byKey(const ValueKey('transactions_error')), findsOneWidget);
    expect(find.text('Không thể tải giao dịch'), findsOneWidget);
    expect(find.text('Chưa có giao dịch nào'), findsNothing);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(providerBuilds, 2);
  });

  testWidgets('waits with a skeleton instead of claiming the list is empty', (
    tester,
  ) async {
    final controller = StreamController<List<Transaction>>();
    addTearDown(controller.close);

    await _pump(tester, transactions: controller.stream, settle: false);

    // The audit found "Chưa có giao dịch nào" showing while the stream was
    // still loading, which reads as a fact rather than a wait.
    expect(find.byKey(const ValueKey('transactions_loading')), findsOneWidget);
    expect(find.text('Chưa có giao dịch nào'), findsNothing);

    controller.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('Chưa có giao dịch nào'), findsOneWidget);
  });

  testWidgets('the Chi | Thu segmented narrows the list', (tester) async {
    await _pump(tester);

    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Lương'), findsOneWidget);
    expect(find.textContaining('2 giao dịch'), findsOneWidget);

    await tester.tap(find.text('Chi'));
    await tester.pumpAndSettle();

    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Lương'), findsNothing);
    expect(find.textContaining('1 giao dịch'), findsOneWidget);
  });

  testWidgets('the filter button badge counts what is applied', (tester) async {
    final container = await _pump(tester);

    expect(find.text('1'), findsNothing);

    await tester.tap(find.text('Thu'));
    await tester.pumpAndSettle();

    // Type counts as one applied filter.
    expect(container.read(transactionFilterProvider).activeCount, 1);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('searching filters by note and says so when nothing matches', (
    tester,
  ) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField), 'trưa');
    await tester.pumpAndSettle();

    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Lương'), findsNothing);

    await tester.enterText(find.byType(TextField), 'không có gì khớp');
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy giao dịch nào'), findsOneWidget);
    expect(find.text('Chưa có giao dịch nào'), findsNothing);
  });

  testWidgets('an applied category filter shows a removable chip', (
    tester,
  ) async {
    final container = await _pump(tester);

    container.read(transactionFilterProvider.notifier).state = container
        .read(transactionFilterProvider)
        .toggleCategory('food');
    await tester.pumpAndSettle();

    // The chip names the category and offers the ✕ that clears it.
    expect(find.text('Lương'), findsNothing);
    expect(find.byIcon(LucideIcons.x), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(container.read(transactionFilterProvider).categoryIds, isEmpty);
    expect(find.text('Lương'), findsOneWidget);
  });
}
