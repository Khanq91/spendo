import 'package:flutter/material.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/domain/period.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    // Month-only: this selector has no way to show a multi-month span.
    // Phase 4 replaces the whole widget when Wallet detail — its last caller
    // — is redesigned.
    final picked = await PeriodPickerSheet.show(
      context: context,
      selected: Period.month(month),
      allowCustomRange: false,
    );
    if (picked != null) {
      onMonthPicked(DateTime(picked.start.year, picked.start.month));
    }
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
          icon: const Icon(LucideIcons.chevronLeft),
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
                  LucideIcons.chevronDown,
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
            LucideIcons.chevronRight,
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
