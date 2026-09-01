import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';

/// Deletes [transaction] and offers an undo in a snackbar.
///
/// Replaces the confirmation dialog: a dialog asks before every delete
/// including the ones the user meant, while undo only costs attention when the
/// delete was a mistake. Used by the swipe gesture on the list and by the
/// detail sheet's delete button, so both behave the same.
Future<void> deleteTransactionWithUndo(
  BuildContext context,
  Transaction transaction,
) async {
  final messenger = ScaffoldMessenger.of(context);

  // Built inside the guard: reaching the database can fail before the delete
  // does, and the swipe has already removed the row by this point, so nothing
  // here may throw past the caller.
  final TransactionRepository repo;
  try {
    repo = TransactionRepository();
    await repo.delete(transaction.id);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Không xoá được giao dịch. Thử lại.')),
    );
    return;
  }

  final sign = transaction.isExpense ? '−' : '+';
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text('Đã xoá $sign${formatVND(transaction.amount)}'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Hoàn tác',
        onPressed: () async {
          try {
            await repo.restore(transaction);
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Không khôi phục được giao dịch.'),
              ),
            );
          }
        },
      ),
    ),
  );
}
