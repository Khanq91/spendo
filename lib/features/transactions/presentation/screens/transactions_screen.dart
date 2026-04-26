import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../domain/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_list_item.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(filteredTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCategories = categoriesAsync.valueOrNull ?? [];
    final selectedCat = ref.watch(selectedCategoryFilterProvider);
    final month = ref.watch(selectedMonthProvider);
    final cs = Theme.of(context).colorScheme;

    final categoryMap = <String, Category>{};
    for (final c in allCategories) {
      categoryMap[c.id] = c;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _showSearch
            ? TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm...',
            border: InputBorder.none,
            hintStyle: TextStyle(
                fontSize: 15, color: cs.onSurfaceVariant),
          ),
          onChanged: (v) =>
          ref.read(searchQueryProvider.notifier).state = v,
        )
            : Text(
          'Tháng ${month.month}/${month.year}',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search_outlined),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchCtrl.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _CategoryFilterBar(
            categories: allCategories,
            selectedId: selectedCat,
            onSelect: (id) =>
            ref.read(selectedCategoryFilterProvider.notifier).state = id,
          ),
          _MiniSummaryRow(txs: txs),
          const Divider(height: 1),
          Expanded(
            child: txs.isEmpty
                ? _EmptyState(
                hasFilter: selectedCat != null || _showSearch)
                : ListView(
              children: [
                ..._buildGroupedList(context, txs, categoryMap),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
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
      final dayNet = dayTxs.fold<int>(
          0, (s, t) => t.isExpense ? s - t.amount : s + t.amount);
      final isPos = dayNet >= 0;

      widgets.add(
        Container(
          color: cs.surfaceContainerHighest,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
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
                '${isPos ? '+' : '-'}${formatVND(dayNet.abs())}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isPos
                      ? AppTheme.incomeColor
                      : AppTheme.expenseAltColor,
                ),
              ),
            ],
          ),
        ),
      );

      for (final tx in dayTxs) {
        widgets.add(TransactionListItem(
          transaction: tx,
          category: categoryMap[tx.categoryId],
        ));
        widgets.add(Divider(
            height: 1,
            indent: 68,
            endIndent: 16,
            color: cs.outlineVariant));
      }
    }

    return widgets;
  }
}

// ── Category filter bar ───────────────────────────────────────────────────────

class _CategoryFilterBar extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final void Function(String?) onSelect;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _FilterChip(
            label: 'Tất cả',
            selected: selectedId == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 6),
          ...categories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _FilterChip(
              label: cat.name,
              selected: selectedId == cat.id,
              color: cat.color,
              onTap: () =>
                  onSelect(selectedId == cat.id ? null : cat.id),
            ),
          )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : cs.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
            selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? c : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Mini summary row ──────────────────────────────────────────────────────────

class _MiniSummaryRow extends StatelessWidget {
  final List<Transaction> txs;
  const _MiniSummaryRow({required this.txs});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final income =
    txs.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
    final expense =
    txs.where((t) => t.isExpense).fold(0, (s, t) => s + t.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        children: [
          Text(
            '${txs.length} giao dịch',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            '+${formatVND(income)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.incomeColor,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '-${formatVND(expense)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.expenseAltColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? LucideIcons.searchX : LucideIcons.receiptText,
            size: 48,
            color: cs.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'Không tìm thấy giao dịch nào'
                : 'Chưa có giao dịch nào',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 4),
            Text('Tap + để thêm',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}