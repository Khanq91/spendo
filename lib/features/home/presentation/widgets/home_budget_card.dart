import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spendo_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../budget/presentation/widgets/budget_type_sheet.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

/// Month budget progress, or the dashed "set a limit" call to action.
///
/// Both states occupy the same slot so the layout below never shifts when a
/// budget is created.
class HomeBudgetCard extends ConsumerWidget {
  const HomeBudgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(budgetProgressProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: progress == null
          ? const _BudgetCta()
          : _BudgetProgress(
              budget: progress.budget,
              spent: progress.spent,
              percent: progress.percent,
              daysLeft: _daysLeftInMonth(ref.watch(selectedMonthProvider)),
            ),
    );
  }
}

/// Days remaining in [month] — 0 once the month is over, so a past month
/// reads "còn 0 ngày" rather than a negative count.
int _daysLeftInMonth(DateTime month) {
  final now = DateTime.now();
  final lastDay = DateTime(month.year, month.month + 1, 0);
  final today = DateTime(now.year, now.month, now.day);
  final remaining = lastDay.difference(today).inDays;
  return remaining < 0 ? 0 : remaining;
}

class _BudgetProgress extends StatelessWidget {
  const _BudgetProgress({
    required this.budget,
    required this.spent,
    required this.percent,
    required this.daysLeft,
  });

  final int budget;
  final int spent;
  final double percent;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayPercent = (percent * 100).clamp(0, 999).round();

    return SpendoCard(
      key: const ValueKey('home_budget_progress'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => showBudgetTypeSheet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Ngân sách tháng',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$displayPercent%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SpendoProgressBar(value: percent),
          const SizedBox(height: 8),
          Text(
            'Đã chi ${formatVND(spent)} / ${formatVND(budget)} · còn $daysLeft ngày',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCta extends StatelessWidget {
  const _BudgetCta();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PressableScale(
      deferTapToChild: true,
      child: GestureDetector(
        key: const ValueKey('home_budget_cta'),
        onTap: () => showBudgetTypeSheet(context),
        behavior: HitTestBehavior.opaque,
        child: DottedBorderBox(
          radius: AppTheme.radiusCardFeature,
          color: context.spendo.dashedOutline,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(LucideIcons.target, size: 18, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đặt hạn mức cho tháng này',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
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
