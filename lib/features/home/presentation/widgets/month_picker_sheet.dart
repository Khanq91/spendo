import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom sheet chọn tháng/năm cụ thể.
/// Trả về DateTime (ngày 1 của tháng được chọn) qua Navigator.pop.
class MonthPickerSheet extends StatefulWidget {
  final DateTime selected;

  const MonthPickerSheet({super.key, required this.selected});

  @override
  State<MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<MonthPickerSheet> {
  late int _year;
  late int _month;

  static const _months = [
    'Th.1', 'Th.2', 'Th.3', 'Th.4',
    'Th.5', 'Th.6', 'Th.7', 'Th.8',
    'Th.9', 'Th.10', 'Th.11', 'Th.12',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.selected.year;
    _month = widget.selected.month;
  }

  bool _isFuture(int year, int month) {
    final now = DateTime.now();
    return year > now.year || (year == now.year && month > now.month);
  }

  bool _isSelected(int month) => month == _month && _year == widget.selected.year
      ? false // so sánh dưới
      : false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cs = Theme.of(context).colorScheme;
    // Cho phép xem tối đa 3 năm về trước
    final minYear = now.year - 3;
    final canGoPrev = _year > minYear;
    final canGoNext = _year < now.year;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Year selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: canGoPrev
                    ? () => setState(() => _year--)
                    : null,
                icon: Icon(
                  Icons.chevron_left,
                  color: canGoPrev ? cs.onSurface : cs.outlineVariant,
                ),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '$_year',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: canGoNext
                    ? () => setState(() => _year++)
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: canGoNext ? cs.onSurface : cs.outlineVariant,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Month grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: 12,
            itemBuilder: (_, i) {
              final m = i + 1;
              final isCurrentSelection =
                  m == widget.selected.month && _year == widget.selected.year;
              final isToday =
                  m == now.month && _year == now.year;
              final disabled = _isFuture(_year, m);

              Color bgColor = Colors.transparent;
              Color textColor = cs.onSurface;
              Color borderColor = cs.outlineVariant;

              if (disabled) {
                textColor = cs.outlineVariant;
                borderColor = Colors.transparent;
              } else if (isCurrentSelection) {
                bgColor = Theme.of(context).colorScheme.primary;
                textColor = Colors.white;
                borderColor = Theme.of(context).colorScheme.primary;
              } else if (isToday) {
                bgColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
                textColor = Theme.of(context).colorScheme.primary;
                borderColor = Theme.of(context).colorScheme.primary.withOpacity(0.4);
              }

              return GestureDetector(
                onTap: disabled
                    ? null
                    : () => Navigator.pop(context, DateTime(_year, m)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Center(
                    child: Text(
                      _months[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrentSelection || isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}