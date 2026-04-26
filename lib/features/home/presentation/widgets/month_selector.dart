import 'package:flutter/material.dart';
import '../../../../core/utils/date_helpers.dart';

class MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const MonthSelector({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        month.year == now.year && month.month == now.month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          formatMonthYear(month),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: isCurrentMonth ? null : onNext,
          icon: Icon(
            Icons.chevron_right,
            color: isCurrentMonth ? Colors.grey.shade300 : null,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}