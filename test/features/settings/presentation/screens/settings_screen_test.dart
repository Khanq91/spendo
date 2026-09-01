import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/providers/loan_provider.dart';
import 'package:spendo/features/reminders/domain/recurring_reminder.dart';
import 'package:spendo/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:spendo/features/settings/presentation/providers/sepay_provider.dart';
import 'package:spendo/features/settings/presentation/screens/settings_screen.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

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
    colorHex: '#96CEB4',
    iconName: 'work',
    isDefault: true,
    isIncome: true,
    sortOrder: 0,
  ),
];

const _wallets = [
  Wallet(
    id: 'cash',
    name: 'Tiền mặt',
    type: WalletType.cash,
    initialBalance: 0,
    colorHex: '#7A8A5E',
    sortOrder: 0,
    isArchived: false,
  ),
];

/// Records where the hub pushed to, without needing the real screens.
late String? lastRoute;

Widget _app(List<Override> overrides) {
  lastRoute = null;
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      for (final path in [
        '/settings/categories',
        '/settings/appearance',
        '/settings/backup',
        '/settings/bank',
        '/settings/widget',
        '/settings/notifications',
        '/wallets',
        '/loans',
        '/reminders',
      ])
        GoRoute(
          path: path,
          builder: (_, __) {
            lastRoute = path;
            return const Scaffold(body: Text('pushed'));
          },
        ),
    ],
  );

  return ProviderScope(
    overrides: [
      categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
      walletsProvider.overrideWith((ref) => Stream.value(_wallets)),
      loansProvider.overrideWith((ref) => Stream.value(const <Loan>[])),
      remindersProvider.overrideWith(
        (ref) => Stream.value(const <RecurringReminder>[]),
      ),
      sepayAccountsProvider.overrideWith(SepayAccountsNotifier.new),
      ...overrides,
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the hub shows three groups and every entry counts its data', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const []));
    await tester.pump();

    for (final label in ['DỮ LIỆU', 'KẾT NỐI', 'ỨNG DỤNG']) {
      expect(find.text(label), findsOneWidget);
    }

    // The nine flat sections of the old screen collapsed to nine rows.
    for (final row in [
      'Danh mục',
      'Nguồn tiền',
      'Khoản vay',
      'Nhắc nhở',
      'Sao lưu & đồng bộ',
      'Ngân hàng tự động',
      'Widget màn hình chính',
      'Giao diện',
      'Thông báo',
    ]) {
      expect(find.text(row), findsOneWidget, reason: 'missing row: $row');
    }

    // Counts come from the same providers the destination pages use.
    expect(find.text('2'), findsOneWidget); // categories
    expect(find.text('1'), findsOneWidget); // wallets
    expect(find.text('0'), findsNWidgets(2)); // loans + reminders
    expect(find.text('0/4'), findsOneWidget); // widget slots
  });

  testWidgets('every hub row navigates to its own page', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const []));
    await tester.pump();

    const expected = {
      'Danh mục': '/settings/categories',
      'Nguồn tiền': '/wallets',
      'Khoản vay': '/loans',
      'Nhắc nhở': '/reminders',
      'Sao lưu & đồng bộ': '/settings/backup',
      'Ngân hàng tự động': '/settings/bank',
      'Widget màn hình chính': '/settings/widget',
      'Giao diện': '/settings/appearance',
      'Thông báo': '/settings/notifications',
    };

    for (final entry in expected.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(lastRoute, entry.value, reason: 'row "${entry.key}"');

      // Back to the hub for the next row.
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('the whole hub fits one 360×640 screen, footer included', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const []));
    await tester.pump();

    // The point of the hub: the old list ran ~2000px with nine flat sections.
    // Every group now ends on screen, and the footer is the only thing the
    // user has to reach for.
    expect(find.text('ỨNG DỤNG'), findsOneWidget);
    expect(tester.getRect(find.text('Thông báo')).bottom, lessThanOrEqualTo(640));

    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your money, clearly.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
