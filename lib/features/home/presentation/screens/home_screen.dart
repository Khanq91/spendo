import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../budget/presentation/widgets/budget_card.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/widgets/transaction_list_item.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/domain/category.dart';
import '../widgets/summary_card.dart';
import '../widgets/month_selector.dart';

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
          onPrev: () => ref.read(selectedMonthProvider.notifier).state =
              DateTime(month.year, month.month - 1),
          onNext: () => ref.read(selectedMonthProvider.notifier).state =
              DateTime(month.year, month.month + 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (txs) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: SummaryCards(
                  income: summary.income,
                  expense: summary.expense,
                  balance: summary.balance,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: const BudgetCard(),
              ),
            ),
            if (txs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.receiptText,
                          size: 48, color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có giao dịch nào',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + để thêm',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate(
                  _buildGroupedList(context, txs, categoryMap),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList(
      BuildContext context,
      List<Transaction> txs,
      Map<String, Category> categoryMap,
      ) {
    final cs = Theme.of(context).colorScheme;

    final Map<String, List<Transaction>> grouped = {};
    for (final tx in txs) {
      final key =
          '${tx.createdAt.year}-${tx.createdAt.month}-${tx.createdAt.day}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      final dayTxs = entry.value;
      final date = dayTxs.first.createdAt;

      final dayTotal = dayTxs.fold<int>(
        0,
            (sum, t) => t.isExpense ? sum - t.amount : sum + t.amount,
      );
      final isPositive = dayTotal >= 0;

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                formatDayHeader(date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${isPositive ? '+' : ''}${dayTotal < 0 ? '-' : ''}${_absFormatted(dayTotal)} ₫',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isPositive
                      ? AppTheme.incomeColor
                      : AppTheme.expenseAltColor,
                ),
              ),
            ],
          ),
        ),
      );

      widgets.add(const Divider(height: 1, indent: 16, endIndent: 16));

      for (final tx in dayTxs) {
        widgets.add(
          TransactionListItem(
            transaction: tx,
            category: categoryMap[tx.categoryId],
          ),
        );
      }
    }

    return widgets;
  }

  String _absFormatted(int n) {
    return n.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }
}