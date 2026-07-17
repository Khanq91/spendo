import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/motion/motion_spec.dart';
import '../../domain/wallet.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_form_sheet.dart';

class WalletCardHome extends ConsumerStatefulWidget {
  const WalletCardHome({super.key});

  @override
  ConsumerState<WalletCardHome> createState() => _WalletCardHomeState();
}

class _WalletCardHomeState extends ConsumerState<WalletCardHome> {
  late final PageController _pageCtrl;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  void _startAutoPlay(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % count;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _syncAutoPlay(
    int count, {
    required bool reduceMotion,
    required bool isActive,
  }) {
    if (reduceMotion || !isActive) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _startAutoPlay(count);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final cs = Theme.of(context).colorScheme;
    final reduceMotion = MotionSpec.shouldReduceMotion(context);
    final isActive = TickerMode.valuesOf(context).enabled;

    return walletsAsync.when(
      loading: () => const SizedBox.shrink(),
      error:
          (_, __) =>
              _WalletLoadError(onRetry: () => ref.invalidate(walletsProvider)),
      data: (wallets) {
        // Chưa có wallet → CTA đơn giản
        if (wallets.isEmpty) {
          return GestureDetector(
            onTap: () => showModalBottomSheet(
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
                  Icon(LucideIcons.wallet, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thêm nguồn tiền để theo dõi số dư',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          );
        }

        // Khởi động auto-play mỗi khi danh sách wallet thay đổi
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncAutoPlay(
            wallets.length,
            reduceMotion: reduceMotion,
            isActive: isActive,
          );
        });

        // Có wallet → row với carousel ở giữa
        return GestureDetector(
          onTap: () => context.push('/wallets'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: cs.outlineVariant,
                width: 0.8,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.wallet, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                // Carousel chiếm phần còn lại
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: wallets.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (_, i) => _WalletChip(wallet: wallets[i]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Single wallet chip trong carousel ────────────────────────────────────────

class _WalletChip extends ConsumerWidget {
  final Wallet wallet;
  const _WalletChip({required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = wallet.color;
    final balanceAsync = ref.watch(walletBalanceProvider(wallet.id));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      // decoration: BoxDecoration(
      //   border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      //   borderRadius: BorderRadius.circular(8),
      //   color: color.withOpacity(0.08),
      // ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              wallet.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          balanceAsync.when(
            loading: () => const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (balance) {
              final isNeg = balance < 0;
              return Text(
                formatVND(balance),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isNeg ? AppTheme.expenseAltColor : color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WalletLoadError extends StatelessWidget {
  const _WalletLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('wallets-error'),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant, width: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
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
