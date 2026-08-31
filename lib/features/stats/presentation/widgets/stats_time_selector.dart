import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/motion/motion_spec.dart';
import '../providers/stats_provider.dart';
import 'date_range_picker_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget hiển thị & chọn khoảng thời gian trên AppBar của StatsScreen.
class StatsTimeSelector extends ConsumerWidget {
  const StatsTimeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(statsDateRangeProvider);
    final cs = Theme.of(context).colorScheme;
    final isMonth = range.mode == StatsTimeMode.month;

    // Kiểm tra có phải tháng hiện tại không (để disable nút next)
    final now = DateTime.now();
    final isCurrentMonth =
        isMonth &&
        range.start.year == now.year &&
        range.start.month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nút prev — chỉ hiện khi mode = month
        if (isMonth)
          IconButton(
            onPressed: () {
              final cur = range.start;
              ref.read(statsDateRangeProvider.notifier).state =
                  StatsDateRange.fromMonth(DateTime(cur.year, cur.month - 1));
            },
            icon: const Icon(LucideIcons.chevronLeft),
            visualDensity: VisualDensity.compact,
          ),

        // Label — tap để mở picker
        GestureDetector(
          onTap: () => _openPicker(context, ref, range),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color:
                  isMonth
                      ? cs.primary.withValues(alpha: 0.06)
                      : Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.10),
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                AnimatedSwitcher(
                  duration: appMotion.whenMotionAllowed(
                    context,
                    appMotion.valueDuration,
                  ),
                  switchInCurve: appMotion.curveStandard,
                  switchOutCurve: appMotion.curveLayout,
                  child: Text(
                    range.label,
                    key: ValueKey(range.label),
                    style: TextStyle(
                      fontSize: isMonth ? 15 : 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isMonth
                              ? cs.onSurface
                              : Theme.of(context).colorScheme.primary,
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

        // Nút next — chỉ hiện khi mode = month
        if (isMonth)
          IconButton(
            onPressed:
                isCurrentMonth
                    ? null
                    : () {
                      final cur = range.start;
                      ref
                          .read(statsDateRangeProvider.notifier)
                          .state = StatsDateRange.fromMonth(
                        DateTime(cur.year, cur.month + 1),
                      );
                    },
            icon: Icon(
              LucideIcons.chevronRight,
              color: isCurrentMonth ? Colors.grey.shade300 : null,
            ),
            visualDensity: VisualDensity.compact,
          ),

        // Nút reset về tháng hiện tại
        AnimatedSwitcher(
          duration: appMotion.whenMotionAllowed(
            context,
            appMotion.listDuration,
          ),
          switchInCurve: appMotion.curveStandard,
          switchOutCurve: appMotion.curveLayout,
          transitionBuilder:
              (child, anim) => FadeTransition(
                opacity: anim,
                child: SizeTransition(
                  sizeFactor: anim,
                  axis: Axis.horizontal,
                  child: child,
                ),
              ),
          child:
              (isMonth && isCurrentMonth)
                  ? const SizedBox.shrink(key: ValueKey('hidden'))
                  : Padding(
                    key: const ValueKey('reset-btn'),
                    padding: const EdgeInsets.only(left: 2),
                    child: GestureDetector(
                      onTap: () {
                        ref
                            .read(statsDateRangeProvider.notifier)
                            .state = StatsDateRange.fromMonth(
                          DateTime(now.year, now.month),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isMonth ? 'Hôm nay' : 'Tháng này',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }

  void _openPicker(
    BuildContext context,
    WidgetRef ref,
    StatsDateRange current,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => DateRangePickerSheet(
            current: current,
            onPicked: (picked) {
              ref.read(statsDateRangeProvider.notifier).state = picked;
            },
          ),
    );
  }
}
