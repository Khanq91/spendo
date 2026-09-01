import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../../../categories/domain/category.dart';
import '../../domain/transaction.dart';
import 'transaction_detail_sheet.dart';

class TransactionListItem extends ConsumerWidget {
  final Transaction transaction;
  final Category? category;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.category,
  });

  /// `Ăn trưa · 12:30`, or just the time when there is no note.
  String get _subtitle {
    final note = transaction.note;
    final time = formatTime(transaction.createdAt);
    if (note == null || note.isEmpty) return time;
    return '$note · $time';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return SpendoTransactionRow(
      title: category?.name ?? 'Không rõ',
      subtitle: _subtitle,
      iconName: category?.iconName,
      color: category?.color ?? cs.onSurfaceVariant,
      isIncome: transaction.isIncome,
      amountText:
          '${transaction.isExpense ? '−' : '+'}${formatVND(transaction.amount)}',
      badge: transaction.isAutomatic ? const _AutomaticBadge() : null,
      onTap: () => SpendoSheet.showModal<void>(
        context: context,
        builder: (_) => TransactionDetailSheet(
          transaction: transaction,
          category: category,
        ),
      ),
    );
  }
}

/// Marks a row the bank import created rather than the user.
class _AutomaticBadge extends StatelessWidget {
  const _AutomaticBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: ShapeDecoration(
        color: cs.tertiaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.zap, size: 10, color: cs.onTertiaryContainer),
          const SizedBox(width: 3),
          Text(
            'Tự động',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
