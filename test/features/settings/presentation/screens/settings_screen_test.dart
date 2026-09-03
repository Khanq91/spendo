import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/auth/presentation/providers/auth_provider.dart';
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

/// Two loans in the tracking sổ and none in the spending one, so a row that
/// counted both books together would read 2 where it should read 0.
final _trackingLoans = [
  for (final id in ['t1', 't2'])
    Loan(
      id: id,
      title: 'Nợ $id',
      type: LoanType.lent,
      principal: 100000,
      contactName: '',
      startDate: DateTime(2026, 9),
      colorHex: '#5A7230',
      isClosed: false,
      isTrackingOnly: true,
    ),
];

/// Records where the hub pushed to, without needing the real screens.
late String? lastRoute;

/// The cloud flag is on by default here so the hub is exercised in full;
/// `cloudEnabled: false` is what the shipped build looks like today.
Widget _app(List<Override> overrides, {bool cloudEnabled = true}) {
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
        '/settings/reset',
        '/wallets',
        '/loans',
        '/loans-tracking',
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
      trackingLoansProvider.overrideWith((ref) => Stream.value(_trackingLoans)),
      remindersProvider.overrideWith(
        (ref) => Stream.value(const <RecurringReminder>[]),
      ),
      sepayAccountsProvider.overrideWith(SepayAccountsNotifier.new),
      cloudEnabledProvider.overrideWithValue(cloudEnabled),
      authUserProvider.overrideWith((ref) => Stream.value(null)),
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
      'Sổ theo dõi',
      'Nhắc nhở',
      'Sao lưu & đồng bộ',
      'Ngân hàng tự động',
      'Widget màn hình chính',
      'Giao diện',
      'Thông báo',
    ]) {
      expect(find.text(row), findsOneWidget, reason: 'missing row: $row');
    }

    // Counts come from the same providers the destination pages use — and
    // each row counts only the page it opens, so the two sổ do not pool.
    expect(find.text('1'), findsOneWidget); // wallets
    expect(find.text('0'), findsNWidgets(2)); // loans (spending sổ) + reminders
    expect(find.text('2'), findsNWidgets(2)); // categories + tracking sổ
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
      'Sổ theo dõi': '/loans-tracking',
      'Nhắc nhở': '/reminders',
      'Sao lưu & đồng bộ': '/settings/backup',
      'Ngân hàng tự động': '/settings/bank',
      'Widget màn hình chính': '/settings/widget',
      'Giao diện': '/settings/appearance',
      'Thông báo': '/settings/notifications',
      'Đặt lại dữ liệu': '/settings/reset',
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

  testWidgets('the hub stays short enough to take in at a glance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const []));
    await tester.pump();

    // The point of the hub: the old list ran ~2000px with nine flat sections.
    // The last group's header is on screen without scrolling, so the shape of
    // the whole hub is visible at once.
    //
    // The last *row* used to land above the fold too. Sổ theo dõi added a
    // fourth data row and pushed it ~47px under; the hub is still a third of
    // what it replaced, and everything below the fold is one short drag away.
    expect(find.text('ỨNG DỤNG'), findsOneWidget);
    expect(tester.getRect(find.text('ỨNG DỤNG')).bottom, lessThanOrEqualTo(640));

    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.textContaining('Your money, clearly.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with the cloud off, the bank row is not there at all', (
    tester,
  ) async {
    // The shipped build: no account to link a bank to, so no dead entry.
    await tester.pumpWidget(_app(const [], cloudEnabled: false));
    await tester.pump();

    expect(find.text('Ngân hàng tự động'), findsNothing);
    expect(find.text('Sao lưu & đồng bộ'), findsOneWidget);
  });

  testWidgets('with the cloud on but no session, the bank row says so', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const []));
    await tester.pump();

    expect(find.text('Ngân hàng tự động'), findsOneWidget);
    expect(find.text('Cần đăng nhập'), findsOneWidget);
  });

  testWidgets('the hub is a tab, so it carries no back arrow', (tester) async {
    // The shared header always drew one; on the Settings tab there was
    // nothing to pop, and the arrow did nothing.
    await tester.pumpWidget(_app(const []));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Quay lại'), findsNothing);
  });
}
