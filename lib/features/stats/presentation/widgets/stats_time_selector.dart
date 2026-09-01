import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../shared/domain/period.dart';
import '../../../../shared/widgets/motion/motion.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../providers/stats_provider.dart';

/// The period control in the Stats app bar.
///
/// Phase 5 redesigns the Stats screen itself; this now opens the shared
/// [PeriodPickerSheet] so the two time pickers the audit found are down to one.
class StatsTimeSelector extends ConsumerWidget {
  const StatsTimeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsDateRangeProvider);
    final cs = Theme.of(context).colorScheme;
    final isMonth = period.isMonth;
    final isCurrentMonth = period.isCurrentMonth();

    void setPeriod(Period next) =>
        ref.read(statsDateRangeProvider.notifier).state = next;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMonth)
          IconButton(
            onPressed: () => setPeriod(period.previousMonth),
            icon: const Icon(LucideIcons.chevronLeft),
            tooltip: 'Tháng trước',
            visualDensity: VisualDensity.compact,
          ),
        Flexible(
          child: GestureDetector(
            key: const ValueKey('stats_period'),
            onTap: () async {
              final picked = await PeriodPickerSheet.show(
                context: context,
                selected: period,
              );
              if (picked != null) setPeriod(picked);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: cs.primary.withValues(alpha: 0.08),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMonth)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        LucideIcons.calendarRange,
                        size: 14,
                        color: cs.primary,
                      ),
                    ),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: appMotion.whenMotionAllowed(
                        context,
                        appMotion.valueDuration,
                      ),
                      switchInCurve: appMotion.curveStandard,
                      switchOutCurve: appMotion.curveLayout,
                      child: Text(
                        period.label,
                        key: ValueKey(period.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isMonth ? 15 : 13,
                          fontWeight: FontWeight.w600,
                          color: isMonth ? cs.onSurface : cs.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isMonth)
          IconButton(
            onPressed: isCurrentMonth
                ? null
                : () => setPeriod(period.nextMonth),
            icon: const Icon(LucideIcons.chevronRight),
            tooltip: 'Tháng sau',
            disabledColor: cs.outlineVariant,
            visualDensity: VisualDensity.compact,
          ),
        AnimatedSwitcher(
          duration: appMotion.whenMotionAllowed(context, appMotion.listDuration),
          switchInCurve: appMotion.curveStandard,
          switchOutCurve: appMotion.curveLayout,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(
              sizeFactor: anim,
              axis: Axis.horizontal,
              child: child,
            ),
          ),
          child: isCurrentMonth
              ? const SizedBox.shrink(key: ValueKey('hidden'))
              : Padding(
                  key: const ValueKey('reset-btn'),
                  padding: const EdgeInsets.only(left: 2),
                  child: SpendoChip(
                    label: 'Tháng này',
                    onTap: () => setPeriod(PeriodPreset.thisMonth.resolve()),
                  ),
                ),
        ),
      ],
    );
  }
}
