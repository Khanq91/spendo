import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';
import '../../../wallets/presentation/widgets/wallet_form_sheet.dart';

/// Horizontal row of wallet chips, ending in a dashed "+" that adds one.
///
/// Replaces the auto-advancing single-wallet carousel: every wallet is
/// readable at once, so nothing moves on its own and nothing is hidden behind
/// a timer.
class HomeWalletStrip extends ConsumerWidget {
  const HomeWalletStrip({super.key});

  static const _height = 36.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);

    return walletsAsync.when(
      loading: () => const SizedBox(height: _height),
      error: (_, __) => _WalletStripError(
        onRetry: () => ref.invalidate(walletsProvider),
      ),
      data: (wallets) => SizedBox(
        height: _height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: wallets.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => i == wallets.length
              ? const _AddWalletChip()
              : _WalletChip(wallet: wallets[i]),
        ),
      ),
    );
  }
}

class _WalletChip extends ConsumerWidget {
  const _WalletChip({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));

    return PressableScale(
      deferTapToChild: true,
      child: Material(
        color: cs.surfaceContainer,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/wallets/${wallet.id}'),
          child: Container(
            height: HomeWalletStrip._height,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: wallet.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                balanceAsync.when(
                  loading: () => SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (balance) => Text(
                    formatVND(balance),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: balance < 0
                          ? theme.spendo.expense
                          : cs.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddWalletChip extends StatelessWidget {
  const _AddWalletChip();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Thêm nguồn tiền',
      child: PressableScale(
        deferTapToChild: true,
        child: GestureDetector(
          key: const ValueKey('home_add_wallet'),
          behavior: HitTestBehavior.opaque,
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const WalletFormSheet(),
          ),
          child: DottedBorderBox(
            radius: HomeWalletStrip._height / 2,
            color: context.spendo.dashedOutline,
            child: SizedBox(
              width: HomeWalletStrip._height,
              height: HomeWalletStrip._height,
              child: Icon(
                LucideIcons.plus,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletStripError extends StatelessWidget {
  const _WalletStripError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      key: const ValueKey('wallets-error'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(LucideIcons.circleAlert, size: 18, color: cs.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Không thể tải nguồn tiền',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
