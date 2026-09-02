import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/notice/notice.dart';
import '../../../loan/data/loan_repository.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';

/// Deletes [transaction] and offers an undo in a notice.
///
/// Replaces the confirmation dialog: a dialog asks before every delete
/// including the ones the user meant, while undo only costs attention when the
/// delete was a mistake. Used by the swipe gesture on the list and by the
/// detail sheet's delete button, so both behave the same.
Future<void> deleteTransactionWithUndo(
  BuildContext context,
  Transaction transaction,
) async {
  // A loan's transactions are owned by the loan: deleting one here would leave
  // the payment it belongs to pointing at nothing. There is exactly one way to
  // undo it, and it is on the loan (PLAN §2.9).
  if (transaction.source == kLoanTransactionSource) {
    AppNotice.warning('Giao dịch của khoản vay — xoá từ màn khoản vay.');
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
    AppNotice.error('Không xoá được giao dịch. Thử lại.');
    return;
  }

  final sign = transaction.isExpense ? '−' : '+';
  AppNotice.undo(
    'Đã xoá $sign${formatVND(transaction.amount)}',
    onUndo: () async {
      try {
        await repo.restore(transaction);
      } catch (_) {
        AppNotice.error('Không khôi phục được giao dịch.');
      }
    },
  );
}
