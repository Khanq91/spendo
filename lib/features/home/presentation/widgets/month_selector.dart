import 'package:flutter/material.dart';
import '../../../../core/utils/date_helpers.dart';
import 'month_picker_sheet.dart';

class MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onMonthPicked;

  const MonthSelector({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onMonthPicked,
  });

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => MonthPickerSheet(selected: month),
    );
    if (picked != null) onMonthPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          visualDensity: VisualDensity.compact,
        ),

        // Tap vào label để mở picker
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: cs.primary.withValues(alpha: 0.06),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatMonthYear(month),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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

        IconButton(
          onPressed: _isCurrentMonth ? null : onNext,
          icon: Icon(
            Icons.chevron_right,
            color: _isCurrentMonth ? Colors.grey.shade300 : null,
          ),
          visualDensity: VisualDensity.compact,
        ),

        // Nút "Hôm nay" — chỉ hiện khi không ở tháng hiện tại
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
          child: _isCurrentMonth
              ? const SizedBox.shrink(key: ValueKey('hidden'))
              : Padding(
            key: const ValueKey('today-btn'),
            padding: const EdgeInsets.only(left: 2),
            child: GestureDetector(
              onTap: () => onMonthPicked(
                DateTime(DateTime.now().year, DateTime.now().month),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Hôm nay',
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
}
