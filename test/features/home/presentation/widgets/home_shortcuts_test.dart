import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/budget/presentation/providers/category_budget_provider.dart';
import 'package:spendo/features/budget/domain/category_budget.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/home/presentation/screens/features_screen.dart';
import 'package:spendo/features/home/presentation/widgets/home_shortcuts.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/providers/loan_provider.dart';
import 'package:spendo/features/reminders/domain/recurring_reminder.dart';
import 'package:spendo/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';

/// Where the last tap landed, without needing the real destination screens.
late String? lastRoute;

Widget _app({required Widget home, List<Override> overrides = const []}) {
  lastRoute = null;
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => Scaffold(body: home)),
      for (final path in [
        '/loans',
        '/loans-tracking',
        '/reminders',
        '/features',
        '/wallets',
        '/budget',
        '/settings/categories',
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
    overrides: overrides,
    child: MaterialApp.router(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      routerConfig: router,
    ),
  );
}

Future<void> _tapRow(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('home shortcuts', () {
    testWidgets('the row is three destinations plus a way to the rest', (
      tester,
    ) async {
      await tester.pumpWidget(_app(home: const HomeShortcuts()));
      await tester.pumpAndSettle();

      // Ví and Hạn mức left: `home_wallet_strip` and `home_budget_card` sit on
      // this same screen and already lead there.
      expect(find.text('Ví'), findsNothing);
      expect(find.text('Hạn mức'), findsNothing);
      for (final label in ['Vay nợ', 'Sổ theo dõi', 'Nhắc nhở', 'Xem thêm']) {
        expect(find.text(label), findsOneWidget, reason: 'missing: $label');
      }
    });

    testWidgets('every shortcut lands where its label says', (tester) async {
      const expected = {
        'Vay nợ': '/loans',
        'Sổ theo dõi': '/loans-tracking',
        'Nhắc nhở': '/reminders',
        'Xem thêm': '/features',
      };

      for (final entry in expected.entries) {
        await tester.pumpWidget(_app(home: const HomeShortcuts()));
        await tester.pumpAndSettle();

        await _tapRow(tester, entry.key);
        expect(lastRoute, entry.value, reason: 'shortcut "${entry.key}"');
      }
    });
  });

  group('tất cả tính năng', () {
    final overrides = [
      walletsProvider.overrideWith((ref) => Stream.value(const <Wallet>[])),
      loansProvider.overrideWith((ref) => Stream.value(const <Loan>[])),
      trackingLoansProvider.overrideWith(
        (ref) => Stream.value(const <Loan>[]),
      ),
      categoryBudgetsProvider.overrideWith(
        (ref) => Stream.value(const <CategoryBudget>[]),
      ),
      remindersProvider.overrideWith(
        (ref) => Stream.value(const <RecurringReminder>[]),
      ),
      categoriesProvider.overrideWith(
        (ref) => Stream.value(const <Category>[]),
      ),
    ];

    testWidgets('it holds more than the Home row it was opened from', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(home: const FeaturesScreen(), overrides: overrides),
      );
      await tester.pumpAndSettle();

      // Six against Home's three: the longer list, not the same list twice —
      // which is what got the redesign-era screen of this name deleted.
      for (final label in [
        'Ví',
        'Khoản vay',
        'Sổ theo dõi',
        'Hạn mức',
        'Nhắc nhở',
        'Danh mục',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'missing: $label');
      }
      // The permanent tabs stay out of it.
      for (final label in ['Giao dịch', 'Thống kê', 'Cài đặt']) {
        expect(find.text(label), findsNothing, reason: 'duplicate tab: $label');
      }
    });

    testWidgets('every row navigates to its own page', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const expected = {
        'Ví': '/wallets',
        'Khoản vay': '/loans',
        'Sổ theo dõi': '/loans-tracking',
        'Hạn mức': '/budget',
        'Nhắc nhở': '/reminders',
        'Danh mục': '/settings/categories',
      };

      await tester.pumpWidget(
        _app(home: const FeaturesScreen(), overrides: overrides),
      );
      await tester.pumpAndSettle();

      for (final entry in expected.entries) {
        await _tapRow(tester, entry.key);
        expect(lastRoute, entry.value, reason: 'row "${entry.key}"');

        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
      }
    });
  });
}
