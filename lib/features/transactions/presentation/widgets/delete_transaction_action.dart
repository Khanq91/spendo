import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../loan/data/loan_repository.dart';
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

  // A loan's transactions are owned by the loan: deleting one here would leave
  // the payment it belongs to pointing at nothing. There is exactly one way to
  // undo it, and it is on the loan (PLAN §2.9).
  if (transaction.source == kLoanTransactionSource) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Giao dịch của khoản vay — xoá từ màn khoản vay.',
        ),
      ),
    );
    return;
  }


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
