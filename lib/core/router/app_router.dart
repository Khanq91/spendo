import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../features/reminders/presentation/screens/reminders_screen.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../notifications/notification_service.dart';

final _routerNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _routerNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const AppShell(),
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
    GoRoute(
      path: '/reminders',
      builder: (_, __) => const RemindersScreen(),
    ),
  ],
);

/// Gán navigatorKey cho NotificationService sau khi router sẵn sàng.
void initNotificationNavigatorKey() {
  NotificationService.navigatorKey = _routerNavigatorKey;
}

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
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => AddTransactionSheet(
          preselectedCategoryId: widget.categoryId,
          prefillNote: widget.prefillNote,
          prefillAmount: widget.prefillAmount,
        ),
      );
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell();
  }
}