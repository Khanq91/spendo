import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/wallet_icons.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_form_sheet.dart';

/// Screen 06 of the redesign.
class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final archivedAsync = ref.watch(archivedWalletsProvider);
    final netWorthAsync = ref.watch(totalNetWorthProvider);
    final breakdownAsync = ref.watch(totalWalletBreakdownProvider);

    final hasInitialError = walletsAsync.hasError && !walletsAsync.hasValue;
    final isLoading = walletsAsync.isLoading && !walletsAsync.hasValue;
    final wallets = walletsAsync.valueOrNull ?? const <Wallet>[];
    final archived = archivedAsync.valueOrNull ?? const <Wallet>[];

    return Scaffold(
      floatingActionButton: SpendoExtendedFab(
        heroTag: 'wallets_fab',
        label: 'Thêm nguồn tiền',
        onPressed: () => showWalletFormSheet(context),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SpendoScreenHeader(title: 'Nguồn tiền'),
            Expanded(
              child: switch ((hasInitialError, isLoading)) {
                (true, _) => _LoadError(
                  onRetry: () => ref.invalidate(walletsProvider),
                ),
                (_, true) => const _WalletsSkeleton(),
                _ => RevealScope(
                  child: ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    _NetWorthCard(
                      netWorthAsync: netWorthAsync,
                      breakdownAsync: breakdownAsync,
                    ),
                    if (wallets.isEmpty)
                      SpendoEmptyState(
                        icon: LucideIcons.wallet,
                        title: 'Chưa có nguồn tiền nào',
                        message:
                            'Thêm ví, tài khoản ngân hàng để theo dõi số dư',
                        actionLabel: 'Thêm nguồn tiền',
                        onAction: () => showWalletFormSheet(context),
                      )
                    else ...[
                      const SizedBox(height: 6),
                      for (var i = 0; i < wallets.length; i++) ...[
                        if (i > 0) const _WalletDivider(),
                        RevealItem(
                          id: wallets[i].id,
                          child: _WalletTile(wallet: wallets[i]),
                        ),
                      ],
                    ],
                    if (archived.isNotEmpty)
                      _ArchivedSection(wallets: archived),
                  ],
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletDivider extends StatelessWidget {
  const _WalletDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 72,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

// ── Net worth header card ────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({
    required this.netWorthAsync,
    required this.breakdownAsync,
  });

  final AsyncValue<int> netWorthAsync;
  final AsyncValue<({int x1, int x2})> breakdownAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SpendoCard(
        feature: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng số dư',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            netWorthAsync.when(
              loading: () => const SkeletonBlock(width: 180, height: 30),
              error: (_, __) => Text(
                'Chưa tính được',
                style: TextStyle(fontSize: 20, color: cs.onSurfaceVariant),
              ),
              data: (total) => AnimatedMoneyText(
                value: total,
                formatter: (value) => formatVND(value.round()),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: total < 0 ? theme.spendo.expense : cs.onSurface,
                ),
              ),
            ),
            breakdownAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (bd) {
                if (bd.x1 == 0 && bd.x2 == 0) return const SizedBox.shrink();
                return _UsageBar(x1: bd.x1, x2: bd.x2);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// "Đã dùng X / Y" with the shared progress bar underneath.
class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.x1, required this.x2});

  /// Money that came in — initial balance plus income.
  final int x1;

  /// Money that went out.
  final int x2;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Spending more than ever came in is over the limit, not a full bar — so
    // it resolves to the error colour rather than a brimming primary one.
    final ratio = x1 > 0 ? x2 / x1 : (x2 > 0 ? 1.5 : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        SpendoProgressBar(value: ratio),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                'Đã dùng ${formatVND(x2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
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
                fontSize: 12,
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

// ── Wallet row ───────────────────────────────────────────────────────────────

class _WalletTile extends ConsumerWidget {
  const _WalletTile({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));

    return PressableScale(
      deferTapToChild: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/wallets/${wallet.id}'),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        wallet.type.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                balanceAsync.when(
                  loading: () => const SkeletonBlock(width: 84, height: 15),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (balance) => _BalanceColumn(balance: balance),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronRight,
                  size: 17,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = balance < 0;
    final color = isNegative
        ? theme.spendo.expense
        : theme.colorScheme.onSurface;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: AnimatedMoneyText(
              value: balance,
              formatter: (value) => formatVND(value.round()),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // A credit card below zero is normal and a cash wallet below zero is
          // not, so the badge states the fact and leaves the judgement out.
          if (isNegative) ...[
            const SizedBox(height: 3),
            _NegativeBadge(color: color),
          ],
        ],
      ),
    );
  }
}

class _NegativeBadge extends StatelessWidget {
  const _NegativeBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.12),
        shape: const StadiumBorder(),
      ),
      child: Text(
        'Đang âm',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Archived ─────────────────────────────────────────────────────────────────

class _ArchivedSection extends StatefulWidget {
  const _ArchivedSection({required this.wallets});

  final List<Wallet> wallets;

  @override
  State<_ArchivedSection> createState() => _ArchivedSectionState();
}

class _ArchivedSectionState extends State<_ArchivedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final duration = appMotion.whenMotionAllowed(
      context,
      appMotion.listDuration,
    );

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SpendoSectionHeader(
                    label: 'Đã lưu trữ (${widget.wallets.length})',
                    padding: EdgeInsets.zero,
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: duration,
                  curve: appMotion.curveStandard,
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Column(
            children: [
              for (final wallet in widget.wallets)
                _ArchivedTile(wallet: wallet),
            ],
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: duration,
          sizeCurve: appMotion.curveLayout,
        ),
      ],
    );
  }
}

class _ArchivedTile extends StatelessWidget {
  const _ArchivedTile({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Opacity(
            opacity: 0.55,
            child: SpendoIconTile(
              icon: walletTypeIcon(wallet.type),
              color: wallet.color,
              size: 44,
            ),
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
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
                Text(
                  'Đã lưu trữ',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SpendoChip(
            label: 'Khôi phục',
            icon: LucideIcons.archiveRestore,
            onTap: () => WalletRepository().unarchive(wallet.id),
          ),
        ],
      ),
    );
  }
}

// ── Loading / error ──────────────────────────────────────────────────────────

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SpendoEmptyState(
      icon: LucideIcons.circleAlert,
      title: 'Không tải được nguồn tiền',
      message: 'Kiểm tra kết nối rồi thử lại.',
      actionLabel: 'Thử lại',
      onAction: onRetry,
    );
  }
}

class _WalletsSkeleton extends StatelessWidget {
  const _WalletsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('wallets_loading'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const SkeletonBlock(
          height: 118,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < 3; i++) ...[
          const _WalletTileSkeleton(),
          if (i < 2) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _WalletTileSkeleton extends StatelessWidget {
  const _WalletTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SkeletonBlock(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 132, height: 14),
                SizedBox(height: 8),
                SkeletonBlock(width: 88, height: 12),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBlock(width: 76, height: 14),
        ],
      ),
    );
  }
}
