import 'package:flutter/material.dart';
import '../providers/stats_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// BottomSheet cho phép chọn khoảng thời gian thống kê.
class DateRangePickerSheet extends StatelessWidget {
  final StatsDateRange current;
  final ValueChanged<StatsDateRange> onPicked;

  const DateRangePickerSheet({
    super.key,
    required this.current,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            'Chọn khoảng thời gian',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Presets
          _PresetTile(
            label: 'Tháng này',
            subtitle: 'Tháng ${thisMonth.month}/${thisMonth.year}',
            isSelected:
                current.mode == StatsTimeMode.month &&
                current.start.year == thisMonth.year &&
                current.start.month == thisMonth.month,
            onTap: () {
              onPicked(StatsDateRange.fromMonth(thisMonth));
              Navigator.pop(context);
            },
          ),
          _PresetTile(
            label: 'Tháng trước',
            subtitle: 'Tháng ${lastMonth.month}/${lastMonth.year}',
            isSelected:
                current.mode == StatsTimeMode.month &&
                current.start.year == lastMonth.year &&
                current.start.month == lastMonth.month,
            onTap: () {
              onPicked(StatsDateRange.fromMonth(lastMonth));
              Navigator.pop(context);
            },
          ),
          _PresetTile(
            label: '3 tháng gần nhất',
            subtitle: _fmt3Months(now),
            isSelected: _is3MonthPreset(current, now),
            onTap: () {
              final start = DateTime(now.year, now.month - 2);
              onPicked(StatsDateRange.custom(start, now));
              Navigator.pop(context);
            },
          ),
          _PresetTile(
            label: 'Năm nay',
            subtitle: '01/01/${now.year} – nay',
            isSelected: _isYearPreset(current, now),
            onTap: () {
              final start = DateTime(now.year);
              onPicked(StatsDateRange.custom(start, now));
              Navigator.pop(context);
            },
          ),

          const Divider(height: 24),

          // Custom picker
          Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              leading: Icon(
                LucideIcons.calendarRange,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              title: Text(
                'Tùy chọn...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () => _openCustomPicker(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomPicker(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = DateTime(now.year - 3);

    var initialStart = current.start;
    var initialEnd = current.end.subtract(const Duration(days: 1));
    if (initialEnd.isAfter(today)) initialEnd = today;
    if (initialStart.isAfter(initialEnd)) initialStart = initialEnd;
    if (initialStart.isBefore(firstDate)) initialStart = firstDate;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: today,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        final theme = Theme.of(context);
        final cs = theme.colorScheme;
        
        return Theme(
          data: theme.copyWith(
            appBarTheme: theme.appBarTheme.copyWith(
              backgroundColor: theme.scaffoldBackgroundColor,
              iconTheme: IconThemeData(color: cs.onSurface),
            ),
            colorScheme: cs.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surfaceTint: Colors.transparent, // Disable M3 tint
              surface: theme.scaffoldBackgroundColor,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              rangePickerBackgroundColor: theme.scaffoldBackgroundColor,
              rangePickerHeaderBackgroundColor: theme.scaffoldBackgroundColor,
              rangeSelectionBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              rangeSelectionOverlayColor: WidgetStateProperty.all(Colors.transparent),
              dayOverlayColor: WidgetStateProperty.all(Colors.transparent),
              headerForegroundColor: cs.onSurface,
              dividerColor: theme.dividerTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              dayStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: theme.cardTheme.color,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerTheme.color ?? Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerTheme.color ?? Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      onPicked(StatsDateRange.custom(picked.start, picked.end));
      Navigator.pop(context);
    }
  }

  String _fmt3Months(DateTime now) {
    final start = DateTime(now.year, now.month - 2);
    return 'Th.${start.month} – Th.${now.month}/${now.year}';
  }

  bool _is3MonthPreset(StatsDateRange r, DateTime now) {
    if (r.mode != StatsTimeMode.custom) return false;
    final expected = DateTime(now.year, now.month - 2);
    return r.start.year == expected.year && r.start.month == expected.month;
  }

  bool _isYearPreset(StatsDateRange r, DateTime now) {
    if (r.mode != StatsTimeMode.custom) return false;
    return r.start.month == 1 && r.start.day == 1 && r.start.year == now.year;
  }
}

class _PresetTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : null,
        leading: Icon(
          isSelected ? LucideIcons.circleCheck : LucideIcons.circle,
          color: isSelected ? Theme.of(context).colorScheme.primary : cs.outlineVariant,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Theme.of(context).colorScheme.primary : cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        onTap: onTap,
      ),
    );
  }
}
