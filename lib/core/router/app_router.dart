import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/budget/presentation/screens/budget_screen.dart';
import '../../features/loan/presentation/screens/loan_detail_screen.dart';
import '../../features/loan/presentation/screens/loan_list_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/settings/presentation/screens/appearance_screen.dart';
import '../../features/settings/presentation/screens/backup_screen.dart';
import '../../features/settings/presentation/screens/bank_screen.dart';
import '../../features/settings/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/widget_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../features/wallets/presentation/screens/wallets_screen.dart';
import '../../features/wallets/presentation/screens/wallet_detail_screen.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../notifications/notification_service.dart';

final _routerNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _routerNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AppShell()),
    GoRoute(
      path: '/transactions',
      builder: (_, __) => const TransactionsScreen(),
    ),
    GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    // Phase 6 split the 1366-line Settings list into a hub plus one page per
    // group; every row below used to be a section or a sheet in that list.
    GoRoute(
      path: '/settings/categories',
      builder: (_, __) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/settings/appearance',
      builder: (_, __) => const AppearanceScreen(),
    ),
    GoRoute(path: '/settings/backup', builder: (_, __) => const BackupScreen()),
    GoRoute(path: '/settings/bank', builder: (_, __) => const BankScreen()),
    GoRoute(
      path: '/settings/widget',
      builder: (_, __) => const WidgetScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) {
        final categoryId = state.uri.queryParameters['category_id'];
        final note = state.uri.queryParameters['note'];
        final amountStr = state.uri.queryParameters['amount'];
        final amount = amountStr != null ? int.tryParse(amountStr) : null;
        return _AddTransactionPage(
          categoryId: categoryId,
          prefillNote: note,
          prefillAmount: amount,
        );
      },
    ),
    GoRoute(path: '/reminders', builder: (_, __) => const RemindersScreen()),
    GoRoute(path: '/budget', builder: (_, __) => const BudgetScreen()),
    GoRoute(path: '/wallets', builder: (_, __) => const WalletsScreen()),
    GoRoute(
      path: '/wallets/:id',
      builder: (_, state) =>
          WalletDetailScreen(walletId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/loans',
      builder: (_, state) {
        // type = 'borrowed' | 'lent' | null (all)
        final filterType = state.uri.queryParameters['type'];
        return LoanListScreen(filterType: filterType);
      },
    ),
    // The detail screen used to be reached by a bare Navigator.push, so it
    // had no URL and could not be deep-linked or restored.
    GoRoute(
      path: '/loans/:id',
      builder: (_, state) =>
          LoanDetailScreen(loanId: state.pathParameters['id']!),
    ),
  ],
);

void initNotificationNavigatorKey() {
  NotificationService.navigatorKey = _routerNavigatorKey;
}

/// Landing page for the `/add` deep link fired by a reminder notification.
///
/// In-app callers open the sheet directly with `showAddTransactionSheet`;
/// this exists because a notification can launch the app cold, when there is
/// no context to present a sheet from yet. It shows the shell underneath and
/// returns to it once the sheet closes.
class _AddTransactionPage extends StatefulWidget {
  final String? categoryId;
  final String? prefillNote;
  final int? prefillAmount;

  const _AddTransactionPage({
    this.categoryId,
    this.prefillNote,
    this.prefillAmount,
  });

  @override
  State<_AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<_AddTransactionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showAddTransactionSheet(
        context,
        preselectedCategoryId: widget.categoryId,
        prefillNote: widget.prefillNote,
        prefillAmount: widget.prefillAmount,
      );
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell();
  }
}
