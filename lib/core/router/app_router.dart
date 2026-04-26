import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../shared/widgets/app_bottom_nav.dart';

final appRouter = GoRouter(
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
        return _AddTransactionPage(categoryId: categoryId);
      },
    ),
  ],
);

/// Wrapper page — mở AppShell rồi show bottom sheet ngay
class _AddTransactionPage extends StatefulWidget {
  final String? categoryId;
  const _AddTransactionPage({this.categoryId});

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