import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_budget_provider.dart';
import '../widgets/budget_type_sheet.dart';

class BudgetCard extends ConsumerStatefulWidget {
  const BudgetCard({super.key});

  @override
  ConsumerState<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends ConsumerState<BudgetCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(budgetProgressProvider);
    final budgetAsync = ref.watch(currentBudgetProvider);
    final nearLimit = ref.watch(nearLimitCategoriesProvider);
    final cs = Theme.of(context).colorScheme;

    final hasMonthlyBudget = budgetAsync.valueOrNull != null;
    final hasCategoryAlerts = nearLimit.isNotEmpty;

    // Chưa set cả hai → CTA đơn giản
    if (!hasMonthlyBudget && !hasCategoryAlerts) {
      return GestureDetector(
        onTap: _openBudgetTypeSheet,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant, width: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.target, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đặt hạn mức chi tiêu tháng này',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _openBudgetTypeSheet,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _resolveMainColor(progress).withOpacity(0.2),
            width: 0.8,
          ),
          color: _resolveMainColor(progress).withOpacity(0.06),
        ),
        child: Column(
          children: [
            // ── Monthly budget row ──────────────────────────────────────
            if (hasMonthlyBudget && progress != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _MonthlyBudgetRow(progress: progress),
              ),

            // ── Category alerts toggle ──────────────────────────────────
            if (hasCategoryAlerts) ...[
              if (hasMonthlyBudget) const SizedBox(height: 8),
              InkWell(
                onTap: hasCategoryAlerts
                    ? () => setState(() => _expanded = !_expanded)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    hasMonthlyBudget ? 8 : 12,
                    12,
                    _expanded ? 8 : 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.tag,
                        size: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${nearLimit.where((e) => e.isOver).length} danh mục vượt hạn'
                            '${() {
                          final nearCount = nearLimit
                              .where((e) => !e.isOver && e.percent >= 0.7)
                              .length;
                          return nearCount > 0 ? ', $nearCount gần vượt' : '';
                        }()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: nearLimit.any((e) => e.isOver)
                              ? AppTheme.expenseAltColor
                              : Colors.orange,
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Expanded: category list ─────────────────────────────
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _CategoryAlertList(items: nearLimit),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
                sizeCurve: Curves.easeOutCubic,
              ),
            ],

            if (hasMonthlyBudget && !hasCategoryAlerts)
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Color _resolveMainColor(
      ({int budget, int spent, double percent, bool isOver})? progress,
      ) {
    if (progress == null) return AppTheme.primary;
    if (progress.isOver) return AppTheme.expenseAltColor;
    if (progress.percent > 0.8) return Colors.orange;
    return const Color(0xFF6C63FF);
  }

  void _openBudgetTypeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BudgetTypeSheet(),
    );
  }
}

// ── Monthly budget progress row ───────────────────────────────────────────────

class _MonthlyBudgetRow extends StatelessWidget {
  final ({int budget, int spent, double percent, bool isOver}) progress;

  const _MonthlyBudgetRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isOver = progress.isOver;
    final color = isOver
        ? AppTheme.expenseAltColor
        : progress.percent > 0.8
        ? Colors.orange
        : const Color(0xFF6C63FF);

    return Column(
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
              isOver ? 'Vượt hạn mức tháng!' : 'Hạn mức tháng này',
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Expanded category alert list ──────────────────────────────────────────────

class _CategoryAlertList extends ConsumerWidget {
  final List<
      ({
      String categoryId,
      int budget,
      int spent,
      double percent,
      bool isOver,
      })> items;

  const _CategoryAlertList({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCats = ref.watch(expenseCategoriesProvider);
    final catMap = {for (final c in allCats) c.id: c};
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Divider(height: 1, color: cs.outlineVariant),
        ...items.map((item) {
          final cat = catMap[item.categoryId];
          if (cat == null) return const SizedBox.shrink();

          final color = item.isOver
              ? AppTheme.expenseAltColor
              : item.percent >= 0.9
              ? Colors.orange
              : Colors.amber;

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(categoryIcon(cat.iconName),
                        size: 14, color: cat.color),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      item.isOver ? '⚠️ Vượt' : '${(item.percent * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${formatVND(item.spent)} / ${formatVND(item.budget)}',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: item.percent.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }
}