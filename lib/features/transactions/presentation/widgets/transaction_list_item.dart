import 'package:flutter/material.dart';
import '../../domain/transaction.dart';
import '../../../categories/domain/category.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import 'transaction_detail_sheet.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Category? category;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final color =
    isExpense ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final catColor = category?.color ?? Colors.grey;

    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => TransactionDetailSheet(
          transaction: transaction,
          category: category,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _iconEmoji(category?.iconName ?? ''),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Không rõ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (transaction.note != null &&
                      transaction.note!.isNotEmpty)
                    Text(
                      transaction.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      formatTime(transaction.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${formatVND(transaction.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _iconEmoji(String iconName) {
    const map = {
      'restaurant': '🍜',
      'directions_car': '🚗',
      'school': '📚',
      'sports_esports': '🎮',
      'favorite': '💊',
      'shopping_bag': '🛍️',
      'more_horiz': '📦',
      'work': '💼',
      'laptop': '💻',
      'storefront': '🏪',
      'card_giftcard': '🎁',
    };
    return map[iconName] ?? '💰';
  }
}