import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/domain/period.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_filter.dart';
import '../providers/transaction_provider.dart';
import '../widgets/grouped_transaction_sliver.dart';
import '../widgets/transaction_filter_sheet.dart';

/// Screen 03 of the redesign.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = ref.read(transactionFilterProvider).query;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _update(TransactionFilter next) =>
      ref.read(transactionFilterProvider.notifier).state = next;

  Future<void> _pickPeriod() async {
    final current = ref.read(transactionsPeriodProvider);
    final picked = await PeriodPickerSheet.show(
      context: context,
      selected: current,
    );
    if (picked == null || !mounted) return;
    ref.read(transactionsPeriodProvider.notifier).state = picked;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodAsync = ref.watch(periodTransactionsProvider);
    final txs = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final period = ref.watch(transactionsPeriodProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];

    final categoryMap = <String, Category>{for (final c in categories) c.id: c};
    final hasInitialError = periodAsync.hasError && !periodAsync.hasValue;
    final isLoading = periodAsync.isLoading && !periodAsync.hasValue;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    'Giao dịch',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 23),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SpendoSearchBar(
                key: const ValueKey('transactions_search'),
                controller: _searchCtrl,
                onChanged: (value) => _update(filter.copyWith(query: value)),
                onClear: () {
                  _searchCtrl.clear();
                  _update(filter.copyWith(query: ''));
                },
              ),
            ),
            _ControlRow(
              period: period,
              typeFilter: filter.type,
              activeCount: filter.activeCount,
              onPickPeriod: _pickPeriod,
              onStepMonth: period.isMonth
                  ? (next) =>
                        ref.read(transactionsPeriodProvider.notifier).state =
                            next
                  : null,
              onTypeChanged: (type) => _update(filter.copyWith(type: type)),
              onOpenFilters: () => TransactionFilterSheet.show(context),
            ),
            _AppliedFilterChips(
              filter: filter,
              categories: categories,
              wallets: wallets,
              onChanged: _update,
            ),
            if (!hasInitialError) _SummaryLine(txs: txs),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: AnimatedSwitcher(
                duration: appMotion.whenMotionAllowed(
                  context,
                  appMotion.screenDuration,
                ),
                switchInCurve: appMotion.curveStandard,
                switchOutCurve: appMotion.curveStandard,
                child: switch ((hasInitialError, isLoading, txs.isEmpty)) {
                  (true, _, _) => _LoadError(
                    key: const ValueKey('transactions_error'),
                    onRetry: () => ref.invalidate(periodTransactionsProvider),
                  ),
                  // The audit found the list showing "Chưa có giao dịch nào"
                  // while the stream was still loading, which reads as a fact
                  // rather than a wait.
                  (_, true, _) => const _ListSkeleton(
                    key: ValueKey('transactions_loading'),
                  ),
                  (_, _, true) => _Empty(
                    key: const ValueKey('transactions_empty'),
                    isNarrowed: filter.isNarrowed,
                  ),
                  _ => RevealScope(
                    key: const ValueKey('transactions_list'),
                    child: CustomScrollView(
                      slivers: [
                        GroupedTransactionSliver(
                          transactions: txs,
                          categoryMap: categoryMap,
                          style: GroupedTransactionStyle.filledHeader,
                          dismissible: true,
                        ),
                        // Floating nav (= bottom padding) + FAB clearance.
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.paddingOf(context).bottom + 80,
                          ),
                        ),
                      ],
                    ),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period stepper · Chi|Thu · filter button ─────────────────────────────────

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.period,
    required this.typeFilter,
    required this.activeCount,
    required this.onPickPeriod,
    required this.onStepMonth,
    required this.onTypeChanged,
    required this.onOpenFilters,
  });

  final Period period;
  final TransactionTypeFilter typeFilter;
  final int activeCount;
  final VoidCallback onPickPeriod;

  /// Null for a custom span, which has no "next month" to step to.
  final ValueChanged<Period>? onStepMonth;
  final ValueChanged<TransactionTypeFilter> onTypeChanged;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canStepForward = onStepMonth != null && !period.isCurrentMonth();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _StepArrow(
            icon: LucideIcons.chevronLeft,
            tooltip: 'Kỳ trước',
            onTap: onStepMonth == null
                ? null
                : () => onStepMonth!(period.previousMonth),
          ),
          // The label takes only what it needs; the segmented gets the rest
          // and scales down before anything can overflow on a 360dp screen.
          Flexible(
            child: GestureDetector(
              key: const ValueKey('transactions_period'),
              onTap: onPickPeriod,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  period.shortLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          _StepArrow(
            icon: LucideIcons.chevronRight,
            tooltip: 'Kỳ sau',
            onTap: canStepForward
                ? () => onStepMonth!(period.nextMonth)
                : null,
          ),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: SpendoSegmented<TransactionTypeFilter>(
                  options: [
                    for (final type in TransactionTypeFilter.values)
                      (value: type, label: type.label),
                  ],
                  value: typeFilter,
                  onChanged: onTypeChanged,
                  height: 28,
                  horizontalPadding: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: activeCount == 0
                ? 'Lọc giao dịch'
                : 'Lọc giao dịch, $activeCount bộ lọc đang áp',
            child: PressableScale(
              deferTapToChild: true,
              child: GestureDetector(
                key: const ValueKey('transactions_filter_button'),
                onTap: onOpenFilters,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.filter,
                          size: 18,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                      if (activeCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 17),
                            height: 17,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: ShapeDecoration(
                              color: cs.primary,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              '$activeCount',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 32,
          height: 44,
          child: Icon(
            icon,
            size: 20,
            color: onTap == null ? cs.outlineVariant : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Applied filters ──────────────────────────────────────────────────────────

/// One removable chip per applied filter, so what is narrowing the list is
/// visible without opening the sheet.
class _AppliedFilterChips extends StatelessWidget {
  const _AppliedFilterChips({
    required this.filter,
    required this.categories,
    required this.wallets,
    required this.onChanged,
  });

  final TransactionFilter filter;
  final List<Category> categories;
  final List<Wallet> wallets;
  final ValueChanged<TransactionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    if (filter.activeCount == 0) return const SizedBox(height: 4);

    final chips = <Widget>[
      for (final id in filter.categoryIds)
        SpendoChip(
          label:
              categories.where((c) => c.id == id).firstOrNull?.name ??
              'Danh mục đã xoá',
          selected: true,
          onDeleted: () => onChanged(filter.toggleCategory(id)),
        ),
      for (final id in filter.walletIds)
        SpendoChip(
          label:
              wallets.where((w) => w.id == id).firstOrNull?.name ??
              'Ví đã xoá',
          selected: true,
          onDeleted: () => onChanged(filter.toggleWallet(id)),
        ),
    ];

    // The type filter already shows in the segmented control, so it gets no
    // duplicate chip here.
    if (chips.isEmpty) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => chips[i],
        ),
      ),
    );
  }
}

// ── Summary line ─────────────────────────────────────────────────────────────

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.txs});

  final List<Transaction> txs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totals = summarise(txs);

    final parts = <InlineSpan>[
      TextSpan(text: '${totals.count} giao dịch'),
      if (totals.income > 0) ...[
        const TextSpan(text: ' · '),
        TextSpan(
          text: '+${formatVND(totals.income)}',
          style: TextStyle(
            color: theme.spendo.income,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      if (totals.expense > 0) ...[
        const TextSpan(text: ' · '),
        TextSpan(
          text: '−${formatVND(totals.expense)}',
          style: TextStyle(
            color: theme.spendo.expense,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(children: parts),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

// ── States ───────────────────────────────────────────────────────────────────

class _LoadError extends StatelessWidget {
  const _LoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SpendoEmptyState(
      icon: LucideIcons.circleAlert,
      title: 'Không thể tải giao dịch',
      actionLabel: 'Thử lại',
      onAction: onRetry,
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => const SkeletonTransactionItem(),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({super.key, required this.isNarrowed});

  final bool isNarrowed;

  @override
  Widget build(BuildContext context) {
    return SpendoEmptyState(
      icon: isNarrowed ? LucideIcons.searchX : LucideIcons.receiptText,
      title: isNarrowed
          ? 'Không tìm thấy giao dịch nào'
          : 'Chưa có giao dịch nào',
      message: isNarrowed
          ? 'Thử bỏ bớt bộ lọc hoặc đổi kỳ.'
          : 'Chạm + để ghi khoản đầu tiên.',
    );
  }
}
