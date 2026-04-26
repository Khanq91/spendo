import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/presentation/widgets/transaction_list_item.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../../shared/widgets/global_fab.dart';
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

    final categoryMap = <String, Category>{};
    for (final c in categoriesAsync.valueOrNull ?? []) {
      categoryMap[c.id] = c;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
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

            if (txs.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('💸', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có giao dịch nào',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap + để thêm',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate(
                  _buildGroupedList(txs, categoryMap),
                ),
              ),

            // padding cuối để FAB không che item
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: const GlobalFab(),
    );
  }

  List<Widget> _buildGroupedList(
      List<Transaction> txs,
      Map<String, Category> categoryMap,
      ) {
    // group by date
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

      // day header
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
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              Text(
                '${isPositive ? '+' : ''}${dayTotal < 0 ? '-' : ''}${_absFormatted(dayTotal)} ₫',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isPositive
                      ? const Color(0xFF43A047)
                      : const Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ),
      );

      // divider
      widgets.add(const Divider(height: 1, indent: 16, endIndent: 16));

      // items
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