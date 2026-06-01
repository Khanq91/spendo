import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/loan.dart';
import '../providers/loan_provider.dart';

/// Mini card hiển thị tóm tắt khoản vay trên HomeScreen.
/// Ẩn hoàn toàn khi không có khoản vay active.
class LoanMiniCard extends ConsumerWidget {
  const LoanMiniCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(loanSummaryProvider);
    if (summary.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final worst = summary.worstStatus;

    Color badgeColor;
    IconData badgeIcon;
    String badgeLabel;

    switch (worst) {
      case LoanStatus.overdue:
        badgeColor = Colors.red;
        badgeIcon = LucideIcons.alertCircle;
        badgeLabel = 'Quá hạn';
      case LoanStatus.upcoming:
        badgeColor = Colors.orange;
        badgeIcon = LucideIcons.clock;
        badgeLabel = 'Sắp hạn';
      default:
        badgeColor = cs.onSurfaceVariant;
        badgeIcon = LucideIcons.handCoins;
        badgeLabel = '${summary.count} khoản';
    }

    return GestureDetector(
      onTap: () => context.push('/loans'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: worst == LoanStatus.overdue
                ? Colors.red.withOpacity(0.4)
                : worst == LoanStatus.upcoming
                ? Colors.orange.withOpacity(0.4)
                : cs.outlineVariant,
            width: worst == LoanStatus.active ? 0.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, size: 14, color: badgeColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khoản vay',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Hiện số tiền đang vay nếu có, hoặc cho vay
                  Text(
                    summary.totalBorrowed > 0
                        ? formatVND(summary.totalBorrowed)
                        : formatVND(summary.totalLent),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Badge cảnh báo
            if (worst != LoanStatus.active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              )
            else
              Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}