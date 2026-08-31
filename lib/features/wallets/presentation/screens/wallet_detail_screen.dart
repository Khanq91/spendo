import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/widgets/grouped_transaction_sliver.dart';
import '../../../home/presentation/widgets/month_selector.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_form_sheet.dart';

enum _TxFilter { byMonth, all }

class WalletDetailScreen extends ConsumerStatefulWidget {
  final String walletId;
  const WalletDetailScreen({super.key, required this.walletId});

  @override
  ConsumerState<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends ConsumerState<WalletDetailScreen> {
  _TxFilter _filter = _TxFilter.byMonth;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final archivedAsync = ref.watch(archivedWalletsProvider);
    final balanceAsync = ref.watch(walletBalanceProvider(widget.walletId));
    final breakdownAsync = ref.watch(walletBreakdownProvider(widget.walletId));

    final wallet = _findWallet(walletsAsync, archivedAsync);

    if (wallet == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final txsAsync =
        _filter == _TxFilter.byMonth
            ? ref.watch(
              walletTxByMonthProvider((
                walletId: widget.walletId,
                year: _month.year,
                month: _month.month,
              )),
            )
            : ref.watch(walletTxAllProvider(widget.walletId));

    final categoriesAsync = ref.watch(categoriesProvider);
    final categoryMap = <String, Category>{};
    for (final c in categoriesAsync.valueOrNull ?? []) {
      categoryMap[c.id] = c;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          wallet.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 18),
            onPressed: () => _openEdit(context, wallet),
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.ellipsisVertical, size: 20),
            onSelected: (val) => _handleMenu(context, val, wallet),
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(wallet.isArchived ? 'Bỏ lưu trữ' : 'Lưu trữ'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Xoá',
                      style: TextStyle(color: AppTheme.expenseAltColor),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _InfoCard(
              wallet: wallet,
              balanceAsync: balanceAsync,
              breakdownAsync: breakdownAsync,
            ),
          ),
          SliverToBoxAdapter(
            child: _FilterBar(
              filter: _filter,
              month: _month,
              onFilterChange: (f) => setState(() => _filter = f),
              onMonthChange: (m) => setState(() => _month = m),
            ),
          ),
          if (_filter == _TxFilter.byMonth)
            SliverToBoxAdapter(
              child: txsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (txs) => _MiniSummary(txs: txs),
              ),
            ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          txsAsync.when(
            loading:
                () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            error:
                (e, _) =>
                    SliverToBoxAdapter(child: Center(child: Text('Lỗi: $e'))),
            data: (txs) {
              if (txs.isEmpty) {
                return SliverToBoxAdapter(child: _EmptyTx(filter: _filter));
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

  Wallet? _findWallet(
    AsyncValue<List<Wallet>> active,
    AsyncValue<List<Wallet>> archived,
  ) {
    final all = [...active.valueOrNull ?? [], ...archived.valueOrNull ?? []];
    try {
      return all.firstWhere((w) => w.id == widget.walletId);
    } catch (_) {
      return null;
    }
  }

  void _openEdit(BuildContext context, Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => WalletFormSheet(existing: wallet),
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    String val,
    Wallet wallet,
  ) async {
    final repo = WalletRepository();
    if (val == 'archive') {
      if (wallet.isArchived) {
        await repo.unarchive(wallet.id);
      } else {
        await repo.archive(wallet.id);
        if (context.mounted) Navigator.of(context).pop();
      }
    } else if (val == 'delete') {
      final count = await repo.transactionCount(wallet.id);
      if (!context.mounted) return;

      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ví còn $count giao dịch. Hãy lưu trữ ví thay vì xoá.',
            ),
            backgroundColor: AppTheme.expenseAltColor,
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Xoá nguồn tiền?'),
              content: Text(
                'Xoá "${wallet.name}"? Hành động không thể hoàn tác.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Huỷ'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.expenseAltColor,
                  ),
                  child: const Text('Xoá'),
                ),
              ],
            ),
      );

      if (confirm == true) {
        await repo.delete(wallet.id);
        if (context.mounted) Navigator.of(context).pop();
      }
    }
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Wallet wallet;
  final AsyncValue<int> balanceAsync;
  final AsyncValue<({int x1, int x2})> breakdownAsync;

  const _InfoCard({
    required this.wallet,
    required this.balanceAsync,
    required this.breakdownAsync,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = wallet.color;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIcon(wallet.type.iconName),
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.type.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (wallet.note != null && wallet.note!.isNotEmpty)
                      Text(
                        wallet.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Số dư hiện tại',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          balanceAsync.when(
            loading: () => const Text('...'),
            error: (_, __) => const SizedBox.shrink(),
            data: (balance) {
              final isNeg = balance < 0;
              return AnimatedMoneyText(
                value: balance,
                formatter: (value) => formatVND(value.round()),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isNeg ? AppTheme.expenseAltColor : color,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          Text(
            'Ban đầu: ${formatVND(wallet.initialBalance)}',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),

          // Progress bar per wallet
          breakdownAsync.when(
            loading: () => const SizedBox(height: 8),
            error: (_, __) => const SizedBox(height: 8),
            data: (bd) {
              if (bd.x1 == 0 && bd.x2 == 0) return const SizedBox(height: 8);
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _LightProgressBar(x1: bd.x1, x2: bd.x2, color: color),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Progress bar dùng trên nền sáng (card wallet detail)
class _LightProgressBar extends StatelessWidget {
  final int x1;
  final int x2;
  final Color color;

  const _LightProgressBar({
    required this.x1,
    required this.x2,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOverflow = x2 > x1;
    final ratio = x1 > 0 ? (x2 / x1).clamp(0.0, 1.0) : (x2 > 0 ? 1.0 : 0.0);
    final barColor = isOverflow ? Colors.red.shade400 : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedProgressBar(
          value: ratio,
          height: 6,
          trackColor:
              isOverflow
                  ? Colors.red.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.12),
          valueColor: barColor,
          borderRadius: BorderRadius.circular(4),
          semanticLabel: 'Mức sử dụng nguồn tiền',
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'Đã dùng ${formatVND(x2)}',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
            const Spacer(),
            Text(
              '/ ${formatVND(x1)}',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final _TxFilter filter;
  final DateTime month;
  final ValueChanged<_TxFilter> onFilterChange;
  final ValueChanged<DateTime> onMonthChange;

  const _FilterBar({
    required this.filter,
    required this.month,
    required this.onFilterChange,
    required this.onMonthChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              _FilterChip(
                label: 'Theo tháng',
                selected: filter == _TxFilter.byMonth,
                onTap: () => onFilterChange(_TxFilter.byMonth),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Tất cả',
                selected: filter == _TxFilter.all,
                onTap: () => onFilterChange(_TxFilter.all),
              ),
            ],
          ),
          if (filter == _TxFilter.byMonth) ...[
            const SizedBox(height: 8),
            MonthSelector(
              month: month,
              onPrev:
                  () => onMonthChange(DateTime(month.year, month.month - 1)),
              onNext:
                  () => onMonthChange(DateTime(month.year, month.month + 1)),
              onMonthPicked: onMonthChange,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: appMotion.whenMotionAllowed(context, appMotion.tapUpDuration),
        curve: appMotion.curveStandard,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected
                  ? cs.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Mini summary ──────────────────────────────────────────────────────────────

class _MiniSummary extends StatelessWidget {
  final List<Transaction> txs;
  const _MiniSummary({required this.txs});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final income = txs.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => t.isExpense)
        .fold(0, (s, t) => s + t.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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

// ── Empty tx ──────────────────────────────────────────────────────────────────

class _EmptyTx extends StatelessWidget {
  final _TxFilter filter;
  const _EmptyTx({required this.filter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.receiptText, size: 40, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(
            filter == _TxFilter.byMonth
                ? 'Không có giao dịch trong tháng này'
                : 'Chưa có giao dịch nào',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
