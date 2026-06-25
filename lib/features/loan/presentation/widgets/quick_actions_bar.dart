import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../budget/presentation/widgets/budget_type_sheet.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../loan/presentation/providers/loan_provider.dart';

class QuickActionsBar extends ConsumerWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanSummary = ref.watch(loanSummaryDataProvider);
    final budgetProgress = ref.watch(budgetProgressProvider);
    final cs = Theme.of(context).colorScheme;

    // Badge cho budget: cảnh báo nếu vượt hoặc gần vượt (>80%)
    _BadgeData? budgetBadge;
    if (budgetProgress != null) {
      if (budgetProgress.isOver) {
        budgetBadge = _BadgeData(color: AppTheme.expenseAltColor, count: 0);
      } else if (budgetProgress.percent >= 0.8) {
        budgetBadge = _BadgeData(color: Colors.orange, count: 0);
      }
    }

    // Badge cho borrowed
    _BadgeData? borrowedBadge;
    if (loanSummary.remainingBorrowed > 0) {
      final alertCount =
          loanSummary.hasOverdue
              ? loanSummary.overdueCount
              : loanSummary.hasUpcoming
              ? loanSummary.upcomingCount
              : 0;
      borrowedBadge = _BadgeData(
        color:
            loanSummary.hasOverdue
                ? Colors.red
                : loanSummary.hasUpcoming
                ? Colors.orange
                : cs.onSurfaceVariant,
        count: alertCount,
        pulse: loanSummary.hasOverdue || loanSummary.hasUpcoming,
      );
    }

    // Badge cho lent
    _BadgeData? lentBadge;
    if (loanSummary.remainingLent > 0) {
      // Lent: cảnh báo khi sắp đến hạn/quá hạn (dùng cùng count)
      final alertCount =
          loanSummary.hasOverdue
              ? loanSummary.overdueCount
              : loanSummary.hasUpcoming
              ? loanSummary.upcomingCount
              : 0;
      lentBadge = _BadgeData(
        color:
            loanSummary.hasOverdue
                ? Colors.red
                : loanSummary.hasUpcoming
                ? Colors.orange
                : cs.onSurfaceVariant,
        count: alertCount,
        pulse: loanSummary.hasOverdue || loanSummary.hasUpcoming,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Hạn mức
          Expanded(
            child: _ActionChip(
              icon: LucideIcons.target,
              badge: budgetBadge,
              onTap:
                  () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const BudgetTypeSheet(),
                  ),
            ),
          ),
          const SizedBox(width: 10),
          // Đang vay
          Expanded(
            child: _ActionChip(
              icon: LucideIcons.arrowDownLeft,
              badge: borrowedBadge,
              onTap: () => context.push('/loans?type=borrowed'),
            ),
          ),
          const SizedBox(width: 10),
          // Cho vay
          Expanded(
            child: _ActionChip(
              icon: LucideIcons.arrowUpRight,
              badge: lentBadge,
              onTap: () => context.push('/loans?type=lent'),
            ),
          ),
          const SizedBox(width: 10),
          // Placeholder (sẽ implement sau)
          Expanded(
            child: _ActionChip(
              icon: LucideIcons.sparkles,
              badge: null,
              enabled: false,
              onTap: () {}, // disabled
            ),
          ),
          const SizedBox(width: 10),
          // Xem thêm
          Expanded(
            child: _ActionChip(
              icon: LucideIcons.layoutGrid,
              badge: null,
              onTap: () => context.push('/loans'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge data ────────────────────────────────────────────────────────────────

class _BadgeData {
  final Color color;
  final int count; // 0 = chỉ hiện chấm, >0 = hiện số
  final bool pulse;

  const _BadgeData({
    required this.color,
    required this.count,
    this.pulse = false,
  });
}

// ── Single chip ───────────────────────────────────────────────────────────────

class _ActionChip extends StatefulWidget {
  final IconData icon;
  final _BadgeData? badge;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionChip({
    required this.icon,
    required this.badge,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _updatePulse();
  }

  @override
  void didUpdateWidget(_ActionChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.badge?.pulse != widget.badge?.pulse) {
      _updatePulse();
    }
  }

  void _updatePulse() {
    if (widget.badge?.pulse == true) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final badge = widget.badge;
    final isEnabled = widget.enabled;

    final iconColor =
        isEnabled
            ? (badge != null ? badge.color : cs.onSurfaceVariant)
            : cs.outlineVariant;

    return GestureDetector(
      onTap: isEnabled ? widget.onTap : null,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color:
              isEnabled
                  ? (badge != null ? badge.color.withOpacity(0.08) : cs.surface)
                  : cs.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                badge != null
                    ? badge.color.withOpacity(0.25)
                    : cs.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Icon ở giữa
            Center(child: Icon(widget.icon, size: 20, color: iconColor)),

            // Badge góc trên phải
            if (badge != null)
              Positioned(
                top: 6,
                right: 6,
                child: _PulseBadge(badge: badge, pulseAnim: _pulseAnim),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Pulse badge ───────────────────────────────────────────────────────────────

class _PulseBadge extends StatelessWidget {
  final _BadgeData badge;
  final Animation<double> pulseAnim;

  const _PulseBadge({required this.badge, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    final showNumber = badge.count > 1; // >1 mới hiện số, 1 thì chỉ chấm

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) {
        final opacity = badge.pulse ? (0.5 + 0.5 * pulseAnim.value) : 1.0;

        if (!showNumber) {
          // Chỉ chấm tròn nhỏ
          return Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: badge.color,
                shape: BoxShape.circle,
                boxShadow:
                    badge.pulse
                        ? [
                          BoxShadow(
                            color: badge.color.withOpacity(
                              0.5 * pulseAnim.value,
                            ),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                        : null,
              ),
            ),
          );
        }

        // Chấm + số
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: badge.color,
              borderRadius: BorderRadius.circular(10),
              boxShadow:
                  badge.pulse
                      ? [
                        BoxShadow(
                          color: badge.color.withOpacity(0.5 * pulseAnim.value),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                      : null,
            ),
            child: Text(
              badge.count > 9 ? '9+' : '${badge.count}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        );
      },
    );
  }
}
