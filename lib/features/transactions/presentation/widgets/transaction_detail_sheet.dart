import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/transaction.dart';
import '../../data/transaction_repository.dart';
import '../../../categories/domain/category.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/category_icon.dart';
import 'add_transaction_sheet.dart';

class TransactionDetailSheet extends ConsumerWidget {
  final Transaction transaction;
  final Category? category;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = transaction.isExpense;
    final color = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // icon + category
          CategoryIconWidget(
            category: category,
            size: 56,
            iconSize: 26,
          ),
          const SizedBox(height: 8),
          Text(
            category?.name ?? 'Không rõ',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // amount
          Text(
            '${isExpense ? '-' : '+'}${formatVND(transaction.amount)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // detail rows
          _DetailRow(
            icon: LucideIcons.calendarDays,
            label: 'Ngày',
            value: '${formatDayHeader(transaction.createdAt)}, ${formatTime(transaction.createdAt)}',
          ),
          if (transaction.note != null && transaction.note!.isNotEmpty)
            _DetailRow(
              icon: LucideIcons.fileText,
              label: 'Ghi chú',
              value: transaction.note!,
            ),
          _DetailRow(
            icon: isExpense
                ? LucideIcons.arrowUpRight
                : LucideIcons.arrowDownLeft,
            label: 'Loại',
            value: isExpense ? 'Chi tiêu' : 'Thu nhập',
            valueColor: color,
          ),

          const SizedBox(height: 20),

          // action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Xoá'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.expenseColor,
                    side: const BorderSide(
                        color: AppTheme.expenseColor, width: 0.8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openEdit(context),
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Chỉnh sửa'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá giao dịch?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.expenseColor,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await TransactionRepository().delete(transaction.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddTransactionSheet(existing: transaction),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}