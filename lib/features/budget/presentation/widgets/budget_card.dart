import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/budget_provider.dart';
import '../screens/budget_screen.dart';

class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(budgetProgressProvider);
    final budgetAsync = ref.watch(currentBudgetProvider);

    // Chưa set budget
    if (budgetAsync.valueOrNull == null) {
      return GestureDetector(
        onTap: () => _openBudgetScreen(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
              width: 0.8,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.target, size: 20, color: Colors.grey.shade400),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đặt hạn mức chi tiêu tháng này',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      );
    }

    if (progress == null) return const SizedBox.shrink();

    final isOver = progress.isOver;
    final color = isOver
        ? const Color(0xFFE53935)
        : progress.percent > 0.8
        ? const Color(0xFFFFA726)
        : const Color(0xFF6C63FF);

    return GestureDetector(
      onTap: () => _openBudgetScreen(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOver ? LucideIcons.triangleAlert : LucideIcons.target,
                  size: 13,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  isOver ? 'Vượt hạn mức!' : 'Hạn mức tháng này',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress.percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.percent.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  formatVND(progress.spent),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  ' / ${formatVND(progress.budget)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openBudgetScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const BudgetScreen(),
    );
  }
}