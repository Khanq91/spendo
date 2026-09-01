import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/wallet_icons.dart';
import '../../../../shared/domain/period.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../../transactions/presentation/widgets/grouped_transaction_sliver.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_form_sheet.dart';

enum _TxScope { byMonth, all }

/// Screen 07 of the redesign.
class WalletDetailScreen extends ConsumerStatefulWidget {
  const WalletDetailScreen({super.key, required this.walletId});

  final String walletId;

  @override
  ConsumerState<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends ConsumerState<WalletDetailScreen> {
  _TxScope _scope = _TxScope.byMonth;
  Period _period = Period.month(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletsAsync = ref.watch(walletsProvider);
    final archivedAsync = ref.watch(archivedWalletsProvider);

    final wallet = _findWallet(walletsAsync, archivedAsync);
    if (wallet == null) {
      // Both branches used to show the same endless spinner, so a wallet
      // deleted from elsewhere left the screen spinning forever.
      final settled = walletsAsync.hasValue && archivedAsync.hasValue;
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SpendoScreenHeader(title: 'Nguồn tiền'),
              Expanded(
                child: settled
                    ? SpendoEmptyState(
                        icon: LucideIcons.circleAlert,
                        title: 'Nguồn tiền không còn tồn tại',
                        message: 'Có thể ví đã bị xoá ở nơi khác.',
                        actionLabel: 'Quay lại',
                        onAction: () => Navigator.of(context).maybePop(),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      );
    }

    final txsAsync = _scope == _TxScope.byMonth
        ? ref.watch(
            walletTxByMonthProvider((
              walletId: widget.walletId,
              year: _period.start.year,
              month: _period.start.month,
            )),
          )
        : ref.watch(walletTxAllProvider(widget.walletId));

    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final categoryMap = <String, Category>{for (final c in categories) c.id: c};

    return Scaffold(
      floatingActionButton: SpendoExtendedFab(
        heroTag: 'wallet_detail_fab',
        label: 'Thêm giao dịch',
        onPressed: () => showAddTransactionSheet(
          context,
          preselectedWalletId: wallet.id,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SpendoScreenHeader(
              title: wallet.name,
              actions: [
                SpendoHeaderIconButton(
                  icon: LucideIcons.pencil,
                  tooltip: 'Sửa nguồn tiền',
                  size: 19,
                  onPressed: () =>
                      showWalletFormSheet(context, existing: wallet),
                ),
                _WalletMenu(
                  wallet: wallet,
                  onArchive: () => _toggleArchive(wallet),
                  onDelete: () => _delete(wallet),
                ),
              ],
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _InfoCard(wallet: wallet)),
                  SliverToBoxAdapter(
                    child: _ScopeBar(
                      scope: _scope,
                      period: _period,
                      onScopeChanged: (scope) => setState(() => _scope = scope),
                      onPeriodChanged: (period) =>
                          setState(() => _period = period),
                    ),
                  ),
                  if (_scope == _TxScope.byMonth)
                    SliverToBoxAdapter(
                      child: _MiniSummary(
                        txs: txsAsync.valueOrNull ?? const [],
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  ...switch (txsAsync) {
                    AsyncError() when !txsAsync.hasValue => [
                      SliverToBoxAdapter(
                        child: SpendoEmptyState(
                          icon: LucideIcons.circleAlert,
                          title: 'Không tải được giao dịch',
                          actionLabel: 'Thử lại',
                          onAction: () => ref.invalidate(
                            _scope == _TxScope.byMonth
                                ? walletTxByMonthProvider
                                : walletTxAllProvider,
                          ),
                        ),
                      ),
                    ],
                    AsyncLoading() when !txsAsync.hasValue => const [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ],
                    _ => _txSlivers(txsAsync.value ?? const [], categoryMap),
                  },
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _txSlivers(
    List<Transaction> txs,
    Map<String, Category> categoryMap,
  ) {
    if (txs.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: SpendoEmptyState(
              icon: LucideIcons.receiptText,
              title: _scope == _TxScope.byMonth
                  ? 'Không có giao dịch trong kỳ này'
                  : 'Chưa có giao dịch nào',
            ),
          ),
        ),
      ];
    }
    return [
      GroupedTransactionSliver(
        transactions: txs,
        categoryMap: categoryMap,
        dismissible: true,
      ),
    ];
  }

  Wallet? _findWallet(
    AsyncValue<List<Wallet>> active,
    AsyncValue<List<Wallet>> archived,
  ) {
    final all = [
      ...active.valueOrNull ?? const <Wallet>[],
      ...archived.valueOrNull ?? const <Wallet>[],
    ];
    return all.where((w) => w.id == widget.walletId).firstOrNull;
  }

  Future<void> _toggleArchive(Wallet wallet) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = WalletRepository();

    if (wallet.isArchived) {
      await repo.unarchive(wallet.id);
      return;
    }

    await repo.archive(wallet.id);
    // Archiving used to pop with no way back, while deleting — the more
    // destructive of the two — asked first. Undo evens them out.
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Đã lưu trữ ${wallet.name}'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => repo.unarchive(wallet.id),
        ),
      ),
    );
    navigator.pop();
  }

  Future<void> _delete(Wallet wallet) async {
    final repo = WalletRepository();
    final count = await repo.transactionCount(wallet.id);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (count > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Ví còn $count giao dịch. Hãy lưu trữ ví thay vì xoá.',
          ),
        ),
      );
      return;
    }

    // No undo here: unlike a transaction, a wallet with no rows leaves nothing
    // to restore it from, so the confirmation stays.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá nguồn tiền?'),
        content: Text('Xoá "${wallet.name}"? Hành động không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await repo.delete(wallet.id);
    if (mounted) Navigator.of(context).pop();
  }
}

// ── Header menu ──────────────────────────────────────────────────────────────

class _WalletMenu extends StatelessWidget {
  const _WalletMenu({
    required this.wallet,
    required this.onArchive,
    required this.onDelete,
  });

  final Wallet wallet;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Tuỳ chọn',
      icon: const Icon(LucideIcons.ellipsisVertical, size: 20),
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      onSelected: (value) =>
          value == 'archive' ? onArchive() : onDelete(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(
                wallet.isArchived
                    ? LucideIcons.archiveRestore
                    : LucideIcons.archive,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(wallet.isArchived ? 'Bỏ lưu trữ' : 'Lưu trữ'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, size: 18, color: cs.error),
              const SizedBox(width: 12),
              Text('Xoá', style: TextStyle(color: cs.error)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info card ────────────────────────────────────────────────────────────────

class _InfoCard extends ConsumerWidget {
  const _InfoCard({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));
    final breakdownAsync = ref.watch(walletBreakdownProvider(wallet.id));

    final note = wallet.note;
    final subtitle = note == null || note.isEmpty
        ? wallet.type.label
        : '${wallet.type.label} · $note';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SpendoCard(
        feature: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SpendoIconTile(
                  icon: walletTypeIcon(wallet.type),
                  color: wallet.color,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        wallet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 14),
            Text(
              'Số dư hiện tại',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            balanceAsync.when(
              loading: () => const SkeletonBlock(width: 170, height: 30),
              error: (_, __) => Text(
                'Chưa tính được',
                style: TextStyle(fontSize: 20, color: cs.onSurfaceVariant),
              ),
              data: (balance) => AnimatedMoneyText(
                value: balance,
                formatter: (value) => formatVND(value.round()),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: balance < 0 ? theme.spendo.expense : cs.onSurface,
                ),
              ),
            ),
            Text(
              'Ban đầu: ${formatVND(wallet.initialBalance)}',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            breakdownAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (bd) {
                if (bd.x1 == 0 && bd.x2 == 0) return const SizedBox.shrink();
                return _WalletUsageBar(x1: bd.x1, x2: bd.x2);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletUsageBar extends StatelessWidget {
  const _WalletUsageBar({required this.x1, required this.x2});

  final int x1;
  final int x2;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = x1 > 0 ? x2 / x1 : (x2 > 0 ? 1.5 : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SpendoProgressBar(value: ratio, height: 6),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                'Đã dùng ${formatVND(x2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: cs.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '/ ${formatVND(x1)}',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 11.5,
                color: cs.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Scope bar ────────────────────────────────────────────────────────────────

class _ScopeBar extends StatelessWidget {
  const _ScopeBar({
    required this.scope,
    required this.period,
    required this.onScopeChanged,
    required this.onPeriodChanged,
  });

  final _TxScope scope;
  final Period period;
  final ValueChanged<_TxScope> onScopeChanged;
  final ValueChanged<Period> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 0),
      child: Row(
        children: [
          Flexible(
            child: SpendoSegmented<_TxScope>(
              value: scope,
              onChanged: onScopeChanged,
              expand: true,
              height: 30,
              horizontalPadding: 12,
              options: const [
                (value: _TxScope.byMonth, label: 'Theo tháng'),
                (value: _TxScope.all, label: 'Tất cả'),
              ],
            ),
          ),
          // The stepper drops its arrows here: the segmented control already
          // claims most of a 360dp line, and the label still opens the picker,
          // which reaches every month the arrows could.
          if (scope == _TxScope.byMonth)
            SpendoPeriodStepper(
              period: period,
              onChanged: onPeriodChanged,
              showArrows: false,
              maxLabelWidth: 84,
            ),
        ],
      ),
    );
  }
}

// ── Mini summary ─────────────────────────────────────────────────────────────

class _MiniSummary extends StatelessWidget {
  const _MiniSummary({required this.txs});

  final List<Transaction> txs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final income = txs.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
    final expense = txs
        .where((t) => t.isExpense)
        .fold(0, (s, t) => s + t.amount);

    final muted = TextStyle(
      fontSize: 12,
      color: cs.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '${txs.length} giao dịch · '),
            TextSpan(
              text: '+${formatVND(income)}',
              style: muted.copyWith(
                color: theme.spendo.income,
                fontWeight: FontWeight.w600,
              ),
            ),
            const TextSpan(text: ' · '),
            TextSpan(
              text: '−${formatVND(expense)}',
              style: muted.copyWith(
                color: theme.spendo.expense,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: muted,
      ),
    );
  }
}
