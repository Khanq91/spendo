import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/core/theme/spendo_colors.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:spendo/features/categories/presentation/providers/category_provider.dart';
import 'package:spendo/features/categories/presentation/screens/categories_screen.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:spendo/features/loan/presentation/providers/loan_provider.dart';
import 'package:spendo/features/loan/presentation/screens/loan_list_screen.dart';
import 'package:spendo/features/reminders/domain/recurring_reminder.dart';
import 'package:spendo/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:spendo/features/reminders/presentation/screens/reminders_screen.dart';
import 'package:spendo/features/settings/presentation/screens/appearance_screen.dart';
import 'package:spendo/features/settings/presentation/screens/notifications_screen.dart';
import 'package:spendo/features/settings/presentation/screens/settings_screen.dart';
import 'package:spendo/features/settings/presentation/screens/widget_screen.dart';
import 'package:spendo/features/wallets/domain/wallet.dart';
import 'package:spendo/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:spendo/features/wallets/presentation/screens/wallets_screen.dart';

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
    initialBalance: 1250000,
    colorHex: '#7A8A5E',
    sortOrder: 0,
    isArchived: false,
  ),
];

List<Override> _overrides() => [
  categoriesProvider.overrideWith((ref) => Stream.value(_categories)),
  categoryTransactionCountsProvider.overrideWith(
    (ref) => Stream.value(const {'food': 4}),
  ),
  walletsProvider.overrideWith((ref) => Stream.value(_wallets)),
  archivedWalletsProvider.overrideWith((ref) => Stream.value(const <Wallet>[])),
  totalNetWorthProvider.overrideWith((ref) => Stream.value(1250000)),
  totalWalletBreakdownProvider.overrideWith(
    (ref) => Stream.value((x1: 2000000, x2: 750000)),
  ),
  walletBalanceProvider.overrideWith((ref, id) => Stream.value(1250000)),
  loansProvider.overrideWith((ref) => Stream.value(const <Loan>[])),
  paidByLoanProvider.overrideWith((ref) => Stream.value(const <String, int>{})),
  remindersProvider.overrideWith(
    (ref) => Stream.value(const <RecurringReminder>[]),
  ),
];

/// Every screen that can be driven from stubbed providers alone.
final _screens = <String, Widget Function()>{
  'Cài đặt': () => const SettingsScreen(),
  'Danh mục': () => const CategoriesScreen(),
  'Giao diện': () => const AppearanceScreen(),
  'Widget': () => const WidgetScreen(),
  'Thông báo': () => const NotificationsScreen(),
  'Nguồn tiền': () => const WalletsScreen(),
  'Khoản vay': () => const LoanListScreen(),
  'Nhắc nhở': () => const RemindersScreen(),
};

Future<void> _pump(WidgetTester tester, Widget screen, Brightness brightness) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(),
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        darkTheme: AppTheme.dark(AppColorScheme.roseDefault),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: screen,
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('every screen renders in both themes', () {
    for (final entry in _screens.entries) {
      for (final brightness in Brightness.values) {
        testWidgets('${entry.key} · ${brightness.name}', (tester) async {
          tester.view.physicalSize = const Size(390, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await _pump(tester, entry.value(), brightness);
          await tester.pump();

          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('dark surfaces stay warm brown, never pure black', (
    tester,
  ) async {
    // `01-tokens.md`: "nâu ấm, không đen thuần".
    final dark = AppTheme.dark(AppColorScheme.roseDefault).colorScheme;

    for (final surface in [
      dark.surface,
      dark.surfaceContainerLowest,
      dark.surfaceContainerLow,
      dark.surfaceContainer,
      dark.surfaceContainerHighest,
    ]) {
      expect(surface, isNot(Colors.black));
      // Warm: red channel above blue.
      expect(
        surface.r,
        greaterThan(surface.b),
        reason: '$surface should be warm',
      );
    }
  });

  testWidgets('the two themes really do differ on surface and text', (
    tester,
  ) async {
    final light = AppTheme.light(AppColorScheme.roseDefault);
    final dark = AppTheme.dark(AppColorScheme.roseDefault);

    expect(light.colorScheme.surface, isNot(dark.colorScheme.surface));
    expect(light.colorScheme.onSurface, isNot(dark.colorScheme.onSurface));
    // Brand is deliberately shared; primary lifts in dark for contrast.
    expect(light.spendo.brand, dark.spendo.brand);
    expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
    // Income/expense have to stay legible on a dark ground.
    expect(light.spendo.income, isNot(dark.spendo.income));
    expect(light.spendo.expense, isNot(dark.spendo.expense));
  });
}
