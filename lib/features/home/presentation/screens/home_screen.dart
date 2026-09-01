import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/providers/shell_tab_provider.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/widgets/grouped_transaction_sliver.dart';
import '../widgets/home_balance_header.dart';
import '../widgets/home_budget_card.dart';
import '../widgets/home_shortcuts.dart';
import '../widgets/home_wallet_strip.dart';
import '../widgets/month_picker_sheet.dart';

/// Screen 01 of the redesign.
///
/// The fixed blocks above the list were trimmed from ~460px to ~300px so the
/// recent transactions — the part that changes daily — start above the fold.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final categoryMap = <String, Category>{
      for (final c in categoriesAsync.valueOrNull ?? const <Category>[])
        c.id: c,
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          key: const ValueKey('home_scroll'),
          slivers: [
            const SliverToBoxAdapter(child: _HomeTitleBar()),
            const SliverToBoxAdapter(child: HomeBalanceHeader()),
            const SliverToBoxAdapter(child: HomeBudgetCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            const SliverToBoxAdapter(child: HomeWalletStrip()),
            const SliverToBoxAdapter(child: HomeShortcuts()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Gần đây',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _SeeAllButton(
                      onTap: () => ref.read(shellTabProvider.notifier).state =
                          ShellTab.transactions,
                    ),
                  ],
                ),
              ),
            ),
            txAsync.when(
              loading: () => const _HomeTransactionListSkeleton(),
              error: (_, __) => SliverToBoxAdapter(
                child: _HomeTransactionLoadError(
                  onRetry: () => ref.invalidate(transactionsProvider),
                ),
              ),
              data: (txs) {
                if (txs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: SpendoEmptyState(
                        icon: LucideIcons.receiptText,
                        title: 'Chưa có giao dịch nào',
                        message: 'Chạm + để ghi khoản đầu tiên.',
                      ),
                    ),
                  );
                }
                return GroupedTransactionSliver(
                  transactions: txs,
                  categoryMap: categoryMap,
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}

/// The month label plus the reminders bell.
///
/// The chevron stepper is gone: the label opens the picker, which reaches any
/// month in one gesture instead of one tap per month.
class _HomeTitleBar extends ConsumerWidget {
  const _HomeTitleBar();

  Future<void> _pickMonth(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) =>
          MonthPickerSheet(selected: ref.read(selectedMonthProvider)),
    );
    if (picked != null) {
      ref.read(selectedMonthProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final month = ref.watch(selectedMonthProvider);

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Chọn tháng',
              child: PressableScale(
                deferTapToChild: true,
                child: GestureDetector(
                  key: const ValueKey('home_month_picker'),
                  onTap: () => _pickMonth(context, ref),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          formatMonthYear(month),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 23,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.bell, size: 23),
            tooltip: 'Nhắc nhở',
            onPressed: () => context.push('/reminders'),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('home_see_all'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        'Xem tất cả',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _HomeTransactionLoadError extends StatelessWidget {
  const _HomeTransactionLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('home_error'),
      padding: const EdgeInsets.only(top: 24),
      child: SpendoEmptyState(
        icon: LucideIcons.circleAlert,
        title: 'Không thể tải giao dịch',
        actionLabel: 'Thử lại',
        onAction: onRetry,
      ),
    );
  }
}

class _HomeTransactionListSkeleton extends StatelessWidget {
  const _HomeTransactionListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      key: const ValueKey('home_transaction_loading'),
      delegate: SliverChildBuilderDelegate(
        (_, __) => const SkeletonTransactionItem(),
        childCount: 4,
      ),
    );
  }
}
