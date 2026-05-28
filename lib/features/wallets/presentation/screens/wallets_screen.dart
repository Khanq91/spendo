import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/wallet_repository.dart';
import '../../domain/wallet.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_form_sheet.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final archivedAsync = ref.watch(archivedWalletsProvider);
    final netWorthAsync = ref.watch(totalNetWorthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nguồn tiền',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (wallets) => ListView(
          children: [
            _NetWorthCard(
              netWorthAsync: netWorthAsync,
            ),
            if (wallets.isEmpty)
              _EmptyState(onAdd: () => _openForm(context))
            else ...[
              const SizedBox(height: 8),
              ...wallets.map((w) => _WalletTile(wallet: w)),
            ],
            archivedAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (archived) {
                if (archived.isEmpty) return const SizedBox.shrink();
                return _ArchivedSection(wallets: archived);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: OutlinedButton.icon(
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm nguồn tiền'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const WalletFormSheet(),
    );
  }
}

// ── Net worth header card ─────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  final AsyncValue<int> netWorthAsync;

  const _NetWorthCard({
    required this.netWorthAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng số dư',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                netWorthAsync.when(
                  loading: () => const Text('...',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (total) => Text(
                    formatVND(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wallet tile ───────────────────────────────────────────────────────────────

class _WalletTile extends ConsumerWidget {
  final Wallet wallet;
  const _WalletTile({required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));
    final color = wallet.color;

    return ListTile(
      onTap: () => context.push('/wallets/${wallet.id}'),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(categoryIcon(wallet.type.iconName), size: 20, color: color),
      ),
      title: Text(wallet.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(wallet.type.label,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      trailing: balanceAsync.when(
        loading: () => const SizedBox(
            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => const SizedBox.shrink(),
        data: (balance) {
          final isNegative = balance < 0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatVND(balance.abs()),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isNegative ? AppTheme.expenseAltColor : cs.onSurface,
                ),
              ),
              if (isNegative)
                Text('⚠️ Âm',
                    style: TextStyle(fontSize: 10, color: AppTheme.expenseAltColor)),
            ],
          );
        },
      ),
    );
  }
}

// ── Archived section ──────────────────────────────────────────────────────────

class _ArchivedSection extends StatefulWidget {
  final List<Wallet> wallets;
  const _ArchivedSection({required this.wallets});

  @override
  State<_ArchivedSection> createState() => _ArchivedSectionState();
}

class _ArchivedSectionState extends State<_ArchivedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Đã lưu trữ (${widget.wallets.length})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, size: 16, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: widget.wallets.map((w) => _ArchivedTile(wallet: w)).toList(),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _ArchivedTile extends ConsumerWidget {
  final Wallet wallet;
  const _ArchivedTile({required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final color = wallet.color;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(categoryIcon(wallet.type.iconName), size: 20, color: color.withOpacity(0.5)),
      ),
      title: Text(wallet.name, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
      subtitle: Text('Đã lưu trữ', style: TextStyle(fontSize: 12, color: cs.outlineVariant)),
      trailing: TextButton(
        onPressed: () async => WalletRepository().unarchive(wallet.id),
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        child: const Text('Khôi phục', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.wallet, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text('Chưa có nguồn tiền nào',
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            'Thêm ví, tài khoản ngân hàng để theo dõi số dư',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm nguồn tiền'),
          ),
        ],
      ),
    );
  }
}
