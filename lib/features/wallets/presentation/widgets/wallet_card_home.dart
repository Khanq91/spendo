import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/presentation/providers/amount_visibility_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/wallet.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_form_sheet.dart';

class WalletCardHome extends ConsumerWidget {
  const WalletCardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final netWorthAsync = ref.watch(totalNetWorthProvider);
    final visible = ref.watch(amountVisibleProvider);
    final cs = Theme.of(context).colorScheme;

    return walletsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (wallets) {
        // Chưa có wallet → CTA đơn giản
        if (wallets.isEmpty) {
          return GestureDetector(
            onTap:
                () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const WalletFormSheet(),
                ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant, width: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.wallet,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thêm nguồn tiền để theo dõi số dư',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        }

        // Có wallet → hiển thị tổng + preview
        return GestureDetector(
          onTap: () => context.push('/wallets'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.2),
                width: 0.8,
              ),
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.primary.withOpacity(0.04),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.wallet, size: 18, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview tên các wallet
                      Text(
                        _previewNames(wallets),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Tổng net worth
                netWorthAsync.when(
                  loading:
                      () => const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (total) {
                    final isNeg = total < 0;
                    return Text(
                      visible ? formatVND(total) : '••••••',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isNeg ? AppTheme.expenseAltColor : AppTheme.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }

  String _previewNames(List<Wallet> wallets) {
    if (wallets.length <= 3) {
      return wallets.map((w) => w.name).join(' · ');
    }
    final first3 = wallets.take(3).map((w) => w.name).join(' · ');
    return '$first3 · +${wallets.length - 3} khác';
  }
}
