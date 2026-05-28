import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/stats_provider.dart';
import 'date_range_picker_sheet.dart';

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
    final isCurrentMonth = isMonth &&
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
                  StatsDateRange.fromMonth(
                DateTime(cur.year, cur.month - 1),
              );
            },
            icon: const Icon(Icons.chevron_left),
            visualDensity: VisualDensity.compact,
          ),

        // Label — tap để mở picker
        GestureDetector(
          onTap: () => _openPicker(context, ref, range),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isMonth
                  ? cs.primary.withOpacity(0.06)
                  : AppTheme.primary.withOpacity(0.10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMonth)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.date_range_rounded,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                  ),
                Text(
                  range.label,
                  style: TextStyle(
                    fontSize: isMonth ? 15 : 13,
                    fontWeight: FontWeight.w600,
                    color: isMonth ? cs.onSurface : AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
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
            onPressed: isCurrentMonth
                ? null
                : () {
                    final cur = range.start;
                    ref.read(statsDateRangeProvider.notifier).state =
                        StatsDateRange.fromMonth(
                      DateTime(cur.year, cur.month + 1),
                    );
                  },
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentMonth ? Colors.grey.shade300 : null,
            ),
            visualDensity: VisualDensity.compact,
          ),

        // Nút reset về tháng hiện tại
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(
              sizeFactor: anim,
              axis: Axis.horizontal,
              child: child,
            ),
          ),
          child: (isMonth && isCurrentMonth)
              ? const SizedBox.shrink(key: ValueKey('hidden'))
              : Padding(
                  key: const ValueKey('reset-btn'),
                  padding: const EdgeInsets.only(left: 2),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(statsDateRangeProvider.notifier).state =
                          StatsDateRange.fromMonth(
                        DateTime(now.year, now.month),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isMonth ? 'Hôm nay' : 'Tháng này',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
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
      builder: (_) => DateRangePickerSheet(
        current: current,
        onPicked: (picked) {
          ref.read(statsDateRangeProvider.notifier).state = picked;
        },
      ),
    );
  }
}
