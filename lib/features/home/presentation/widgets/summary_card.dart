import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../wallets/presentation/providers/wallet_provider.dart';

class SummaryCards extends ConsumerStatefulWidget {
  final int income;
  final int expense;
  final int balance;

  const SummaryCards({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  ConsumerState<SummaryCards> createState() => _SummaryCardsState();
}

class _SummaryCardsState extends ConsumerState<SummaryCards> {
  bool _balanceVisible = false;

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final breakdownAsync = ref.watch(totalWalletBreakdownProvider);

    return Column(
      children: [
        // Balance card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_darken(cs.primary, 0.22), cs.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số dư',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            _balanceVisible
                                ? formatVND(widget.balance)
                                : '••••••',
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
                  // Toggle button
                  GestureDetector(
                    onTap: () =>
                        setState(() => _balanceVisible = !_balanceVisible),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _balanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              // Progress bar (luôn hiển thị, không bị ẩn theo toggle)
              breakdownAsync.when(
                loading: () => const SizedBox(height: 8),
                error: (_, __) => const SizedBox(height: 8),
                data: (bd) {
                  if (bd.x1 == 0 && bd.x2 == 0) return const SizedBox(height: 8);
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _WalletProgressBar(
                      x1: bd.x1,
                      x2: bd.x2,
                      showLabels: _balanceVisible,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Income + expense mini cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _MiniCard(
                  label: 'Thu nhập',
                  amount: widget.income,
                  color: AppTheme.incomeColor,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniCard(
                  label: 'Chi tiêu',
                  amount: widget.expense,
                  color: AppTheme.expenseAltColor,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Progress bar dùng chung ───────────────────────────────────────────────────

class _WalletProgressBar extends StatelessWidget {
  final int x1; // initial_balance + income (tổng nguồn)
  final int x2; // expense (đã tiêu)
  final bool showLabels;
  final bool isOnDarkBg;

  const _WalletProgressBar({
    required this.x1,
    required this.x2,
    this.showLabels = true,
    this.isOnDarkBg = true,
  });

  @override
  Widget build(BuildContext context) {
    final isOverflow = x2 > x1;
    final ratio = x1 > 0 ? (x2 / x1).clamp(0.0, 1.0) : (x2 > 0 ? 1.0 : 0.0);

    final normalColor = isOnDarkBg ? Colors.white70 : Colors.green.shade400;
    final warningColor = isOnDarkBg ? Colors.orangeAccent : Colors.orange;
    final overflowColor = isOnDarkBg ? Colors.redAccent : Colors.red;
    final trackColor = isOnDarkBg
        ? Colors.white.withOpacity(0.2)
        : Colors.grey.withOpacity(0.15);

    final barColor = isOverflow ? overflowColor : normalColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 5,
            child: Stack(
              children: [
                // Nền (warning color khi overflow, track color bình thường)
                Container(
                  width: double.infinity,
                  color: isOverflow
                      ? overflowColor.withOpacity(0.3)
                      : trackColor,
                ),
                // Bar chính — clamp 100%
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (showLabels) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Đã dùng ${formatVND(x2)}',
                style: TextStyle(
                  fontSize: 10,
                  color: isOnDarkBg
                      ? Colors.white60
                      : Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Text(
                '/ ${formatVND(x1)}',
                style: TextStyle(
                  fontSize: 10,
                  color: isOnDarkBg
                      ? Colors.white60
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Exported để dùng ở wallets_screen và wallet_detail_screen ─────────────────

/// Progress bar dùng ở màn hình ngoài (không có dark bg)
class WalletProgressBar extends StatelessWidget {
  final int x1;
  final int x2;
  final bool showLabels;

  const WalletProgressBar({
    super.key,
    required this.x1,
    required this.x2,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return _WalletProgressBar(
      x1: x1,
      x2: x2,
      showLabels: showLabels,
      isOnDarkBg: false,
    );
  }
}

// ── Mini card ─────────────────────────────────────────────────────────────────

class _MiniCard extends StatefulWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const _MiniCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  State<_MiniCard> createState() => _MiniCardState();
}

class _MiniCardState extends State<_MiniCard> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 14, color: widget.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  _visible ? formatVND(widget.amount) : '••••••',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Toggle button
          GestureDetector(
            onTap: () => setState(() => _visible = !_visible),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _visible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: cs.onSurfaceVariant,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}