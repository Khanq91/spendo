import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../wallets/presentation/widgets/wallet_card_home.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/widgets/grouped_transaction_sliver.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/domain/category.dart';
import '../widgets/feature_grid.dart';
import '../widgets/home_feature_actions.dart';
import '../widgets/summary_card.dart';
import '../widgets/month_selector.dart';
import '../../../../shared/widgets/motion/motion.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final txAsync = ref.watch(transactionsProvider);
    final summary = ref.watch(summaryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cs = Theme.of(context).colorScheme;

    final categoryMap = <String, Category>{};
    for (final c in categoriesAsync.valueOrNull ?? []) {
      categoryMap[c.id] = c;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: MonthSelector(
          month: month,
          onPrev:
              () =>
                  ref.read(selectedMonthProvider.notifier).state = DateTime(
                    month.year,
                    month.month - 1,
                  ),
          onNext:
              () =>
                  ref.read(selectedMonthProvider.notifier).state = DateTime(
                    month.year,
                    month.month + 1,
                  ),
          onMonthPicked:
              (picked) =>
                  ref.read(selectedMonthProvider.notifier).state = picked,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        key: const ValueKey('home_scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: SummaryCards(
                income: summary.income,
                expense: summary.expense,
                balance: summary.balance,
              ),
            ),
          ),

          // WalletCardHome
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const WalletCardHome(),
            ),
          ),

          // Feature grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: FeatureGrid(actions: buildHomeFeatureActions(context)),
            ),
          ),

          txAsync.when(
            loading: () => const _HomeTransactionListSkeleton(),
            error:
                (e, _) => SliverToBoxAdapter(
                  child: _HomeTransactionLoadError(
                    onRetry: () => ref.invalidate(transactionsProvider),
                  ),
                ),
            data: (txs) {
              if (txs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.receiptText,
                          size: 48,
                          color: cs.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có giao dịch nào',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + để thêm',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
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
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _HomeTransactionLoadError extends StatelessWidget {
  const _HomeTransactionLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      key: const ValueKey('home_error'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circleAlert, size: 32, color: cs.error),
            const SizedBox(height: 8),
            Text(
              'Không thể tải giao dịch',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
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
