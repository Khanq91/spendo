import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';

import '../../../core/db/powersync_db.dart' as app_db;
import '../domain/loan.dart';
import '../presentation/providers/loan_provider.dart';
import 'loan_category_resolver.dart';

/// The `transactions.source` a loan writes.
///
/// Only `'sepay'` was ever checked for (`transaction.isAutomatic`), so a new
/// value is safe; it is what the Giao dịch screen keys its read-only guard on.
const String kLoanTransactionSource = 'loan';

/// Told that a loan's instalment reminders may be out of date.
///
/// Every change that moves the waterfall has to be followed by a reschedule,
/// and the repository is the one place that sees all of them. It is a hook
/// rather than a direct call so the data layer keeps no notification
/// dependency, and so tests can run without a plugin behind them: the app
/// installs the real implementation at startup, and the default does nothing.
typedef LoanScheduleListener = Future<void> Function(String loanId);

/// Told that instalments are about to stop existing, while their ids can still
/// be read — a notification id is derived from the instalment id, so this is
/// the last moment the reminders can be found.
typedef LoanScheduleCancelListener =
    Future<void> Function(Iterable<String> installmentIds);

LoanScheduleListener _onScheduleChanged = _noopChanged;
LoanScheduleCancelListener _onScheduleCancelled = _noopCancelled;

Future<void> _noopChanged(String _) async {}

Future<void> _noopCancelled(Iterable<String> _) async {}

/// Wires the repository up to the notification layer. Called once, at startup.
void setLoanScheduleListeners({
  required LoanScheduleListener onChanged,
  required LoanScheduleCancelListener onCancelled,
}) {
  _onScheduleChanged = onChanged;
  _onScheduleCancelled = onCancelled;
}

/// Restores the do-nothing defaults, so one test's listener cannot leak into
/// the next.
@visibleForTesting
void resetLoanScheduleListeners() {
  _onScheduleChanged = _noopChanged;
  _onScheduleCancelled = _noopCancelled;
}

class LoanRepository {
  /// Defaults to the app database; tests hand in their own.
  LoanRepository({PowerSyncDatabase? database, LoanCategoryResolver? resolver})
    : _database = database,
      _resolver = resolver ?? LoanCategoryResolver(database: database);

  final PowerSyncDatabase? _database;
  final LoanCategoryResolver _resolver;

  PowerSyncDatabase get _db => _database ?? app_db.db;

  // ── Loans ────────────────────────────────────────────────────────────────

  /// Every loan of one sổ — the two are separate books and never see each
  /// other (PLAN §2.5), so the flag is a WHERE rather than a second method.
  ///
  /// `COALESCE` because the column arrived after the loans did: a row written
  /// before this feature has no value and belongs to the spending book.
  Stream<List<Loan>> watchAll({bool trackingOnly = false}) {
    return _db
        .watch(
          'SELECT * FROM loans WHERE COALESCE(is_tracking_only, 0) = ? '
          'ORDER BY is_closed ASC, start_date DESC',
          parameters: [trackingOnly ? 1 : 0],
        )
        .map((rows) => rows.map(Loan.fromMap).toList());
  }

  /// Every loan of both sổ. The reminder scheduler and the backup want the
  /// lot: a tracking loan is still reminded — reminding is what tracking is
  /// for (PLAN §2.4) — and a backup that dropped one book would lose it.
  Future<List<Loan>> getAll() async {
    final rows = await _db.getAll(
      'SELECT * FROM loans ORDER BY is_closed ASC, start_date DESC',
    );
    return rows.map(Loan.fromMap).toList();
  }

  Future<List<LoanPayment>> getAllPayments() async {
    final rows = await _db.getAll(
      'SELECT * FROM loan_payments ORDER BY paid_at DESC',
    );
    return rows.map(LoanPayment.fromMap).toList();
  }

  /// Inserts [loan] and returns the id it was given, so a caller that wants
  /// to keep going — opening the schedule screen right after saving — does not
  /// have to hunt for the row it just wrote.
  ///
  /// With [fundingWalletId] set, the principal is also written as a real
  /// transaction — money in for a loan taken, money out for one given — and
  /// linked back through `loans.funding_transaction_id`.
  Future<String> add(Loan loan, {String? fundingWalletId}) async {
    final id = await _insertLoan(loan);
    if (fundingWalletId == null) return id;

    final categoryId = await _resolver.resolve(
      LoanCategoryKind.fundingFor(loan.type),
    );
    await _db.writeTransaction((tx) async {
      final rows = await tx.execute(
        '''INSERT INTO transactions(
             id, amount, type, category_id, note, created_at, wallet_id, source
           ) VALUES(uuid(), ?, ?, ?, ?, ?, ?, ?) RETURNING id''',
        [
          loan.principal.toString(),
          loan.type == LoanType.borrowed ? 'income' : 'expense',
          categoryId,
          loan.title,
          loan.startDate.millisecondsSinceEpoch.toString(),
          fundingWalletId,
          kLoanTransactionSource,
        ],
      );
      await tx.execute(
        'UPDATE loans SET funding_transaction_id = ? WHERE id = ?',
        [rows.first['id'] as String, id],
      );
    });
    return id;
  }

  Future<String> _insertLoan(Loan loan) async {
    // `RETURNING` has to run on a write connection: reading it back with a
    // plain `get` lands on the read pool, where the insert is rejected.
    final rows = await _db.execute(
      '''INSERT INTO loans(id, title, type, principal, contact_name,
           start_date, due_date, note, color_hex, is_closed, repayment_mode,
           funding_transaction_id, is_tracking_only)
         VALUES(uuid(), ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?) RETURNING id''',
      [
        loan.title,
        loan.type.name,
        loan.principal.toString(),
        loan.contactName,
        loan.startDate.toIso8601String(),
        loan.dueDate?.toIso8601String(),
        loan.note,
        loan.colorHex,
        loan.repaymentMode.name,
        loan.fundingTransactionId,
        // The only place the flag is ever written. `update` leaves it alone.
        loan.isTrackingOnly ? 1 : 0,
      ],
    );
    return rows.first['id'] as String;
  }

  /// Saves an edit. `is_tracking_only` is not in the SET list on purpose: a
  /// loan cannot change sổ after it is created (PLAN §2.2).
  Future<void> update(Loan loan) async {
    await _db.execute(
      '''UPDATE loans SET title=?, type=?, principal=?, contact_name=?,
           start_date=?, due_date=?, note=?, color_hex=?, is_closed=?,
           repayment_mode=?
         WHERE id=?''',
      [
        loan.title,
        loan.type.name,
        loan.principal.toString(),
        loan.contactName,
        loan.startDate.toIso8601String(),
        loan.dueDate?.toIso8601String(),
        loan.note,
        loan.colorHex,
        loan.isClosed ? 1 : 0,
        loan.repaymentMode.name,
        loan.id,
      ],
    );
  }

  Future<void> close(String id) async {
    await _db.execute(
      'UPDATE loans SET is_closed = 1 WHERE id = ?',
      [id],
    );
    // A settled loan has nothing left to remind about.
    await _onScheduleChanged(id);
  }

  Future<void> reopen(String id) async {
    await _db.execute(
      'UPDATE loans SET is_closed = 0 WHERE id = ?',
      [id],
    );
    await _onScheduleChanged(id);
  }

  /// Deletes the loan, its schedule, its payments and every transaction it
  /// put in a wallet — the payments' and the principal's alike.
  ///
  /// The ids are gathered before the rows that hold them go, and the whole
  /// sweep runs in one write, so a wallet is never left holding a transaction
  /// whose loan is gone.
  Future<void> delete(String id) async {
    // Read while the rows are still there: the notification ids are derived
    // from the instalment ids, so afterwards there would be no way to find
    // the reminders to cancel.
    final doomed = (await getInstallments(id)).map((i) => i.id).toList();

    await _db.writeTransaction((tx) async {
      final linked = await tx.getAll(
        '''SELECT transaction_id FROM loan_payments
           WHERE loan_id = ? AND transaction_id IS NOT NULL''',
        [id],
      );
      final funding = await tx.getOptional(
        'SELECT funding_transaction_id FROM loans WHERE id = ?',
        [id],
      );

      final transactionIds = <String>{
        for (final row in linked) row['transaction_id'] as String,
        if (funding?['funding_transaction_id'] != null)
          funding!['funding_transaction_id'] as String,
      };
      for (final transactionId in transactionIds) {
        await tx.execute('DELETE FROM transactions WHERE id = ?', [
          transactionId,
        ]);
      }

      await tx.execute('DELETE FROM loan_installments WHERE loan_id = ?', [id]);
      await tx.execute('DELETE FROM loan_payments WHERE loan_id = ?', [id]);
      await tx.execute('DELETE FROM loans WHERE id = ?', [id]);
    });

    await _onScheduleCancelled(doomed);
  }

  // ── Installments ──────────────────────────────────────────────────────────

  Stream<List<LoanInstallment>> watchInstallments(String loanId) {
    return _db
        .watch(
          'SELECT * FROM loan_installments WHERE loan_id = ? ORDER BY seq ASC',
          parameters: [loanId],
        )
        .map((rows) => rows.map(LoanInstallment.fromMap).toList());
  }

  Future<List<LoanInstallment>> getInstallments(String loanId) async {
    final rows = await _db.getAll(
      'SELECT * FROM loan_installments WHERE loan_id = ? ORDER BY seq ASC',
      [loanId],
    );
    return rows.map(LoanInstallment.fromMap).toList();
  }

  Future<List<LoanInstallment>> getAllInstallments() async {
    final rows = await _db.getAll(
      'SELECT * FROM loan_installments ORDER BY loan_id ASC, seq ASC',
    );
    return rows.map(LoanInstallment.fromMap).toList();
  }

  /// Every loan's instalments in one query, keyed by loan id — the list screen
  /// needs the next due date of every row at once, which one stream per row
  /// would not give it cheaply.
  Stream<Map<String, List<LoanInstallment>>> watchInstallmentsByLoan() {
    return _db
        .watch('SELECT * FROM loan_installments ORDER BY loan_id ASC, seq ASC')
        .map((rows) {
      final grouped = <String, List<LoanInstallment>>{};
      for (final row in rows) {
        final installment = LoanInstallment.fromMap(row);
        grouped.putIfAbsent(installment.loanId, () => []).add(installment);
      }
      return grouped;
    });
  }

  /// Swaps the loan's whole schedule for [installments] and puts it into
  /// `installment` mode.
  ///
  /// Editing a schedule replaces the set rather than patching rows: the seq
  /// numbers stay dense and in date order for free, and there is no half-saved
  /// state to reason about. An empty list drops the schedule and returns the
  /// loan to free repayment.
  Future<void> replaceInstallments(
    String loanId,
    List<LoanInstallment> installments,
  ) async {
    final replaced = (await getInstallments(loanId)).map((i) => i.id).toList();

    await _db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM loan_installments WHERE loan_id = ?', [
        loanId,
      ]);
      for (var i = 0; i < installments.length; i++) {
        final installment = installments[i];
        await tx.execute(
          '''INSERT INTO loan_installments(id, loan_id, seq, amount, due_date)
             VALUES(uuid(), ?, ?, ?, ?)''',
          [
            loanId,
            i + 1,
            installment.amount.toString(),
            _dateOnly(installment.dueDate).toIso8601String(),
          ],
        );
      }
      await tx.execute('UPDATE loans SET repayment_mode = ? WHERE id = ?', [
        installments.isEmpty
            ? RepaymentMode.free.name
            : RepaymentMode.installment.name,
        loanId,
      ]);
    });

    // The rows are new — every old id is dead, and the reminders keyed to them
    // would otherwise fire for instalments that no longer exist.
    await _onScheduleCancelled(replaced);
    await _onScheduleChanged(loanId);
  }

  /// Drops the schedule and returns the loan to free repayment. Payments are
  /// untouched — they are what actually happened, the schedule was only a plan.
  Future<void> clearInstallments(String loanId) =>
      replaceInstallments(loanId, const []);

  // ── Payments ──────────────────────────────────────────────────────────────

  Stream<List<LoanPayment>> watchPayments(String loanId) {
    return _db
        .watch(
      'SELECT * FROM loan_payments WHERE loan_id = ? ORDER BY paid_at DESC',
      parameters: [loanId],
    )
        .map((rows) => rows.map(LoanPayment.fromMap).toList());
  }

  /// Total paid per loan, keyed by loan id.
  ///
  /// The list shows what is left rather than the principal it started at
  /// (`15-loan-list.md` §L), which needs every loan's payments at once — one
  /// query instead of a stream per row.
  Stream<Map<String, int>> watchPaidByLoan() {
    return _db
        .watch(
          'SELECT loan_id, COALESCE(SUM(CAST(amount AS INTEGER)), 0) '
          'AS total_paid FROM loan_payments GROUP BY loan_id',
        )
        .map(
          (rows) => {
            for (final row in rows)
              row['loan_id'] as String: row['total_paid'] as int,
          },
        );
  }

  Future<int> getTotalPaid(String loanId) async {
    final row = await _db.get(
      'SELECT COALESCE(SUM(CAST(amount AS INTEGER)), 0) as total FROM loan_payments WHERE loan_id = ?',
      [loanId],
    );
    return row['total'] as int;
  }

  /// Records a payment, and with it the transaction that moves the money.
  ///
  /// A repayment is a real expense (or, on a loan you gave, real income), so it
  /// belongs in the wallet and the statistics like any other — [walletId] is
  /// optional the same way it is everywhere else in the app. The two rows are
  /// written together, and [transactionId] lets an undo put back the exact
  /// transaction that was deleted rather than a fresh one.
  Future<void> addPayment({
    required String loanId,
    required int amount,
    required DateTime paidAt,
    String? note,
    LoanType? loanType,
    String? walletId,
    String? title,
    String? transactionId,
    bool withTransaction = true,
  }) async {
    if (!withTransaction || loanType == null) {
      await _db.execute(
        '''INSERT INTO loan_payments(id, loan_id, amount, paid_at, note,
             transaction_id)
           VALUES(uuid(), ?, ?, ?, ?, ?)''',
        [
          loanId,
          amount.toString(),
          paidAt.toIso8601String(),
          note,
          transactionId,
        ],
      );
      await _onScheduleChanged(loanId);
      return;
    }

    final categoryId = await _resolver.resolve(
      LoanCategoryKind.paymentFor(loanType),
    );
    final fallbackNote = loanType == LoanType.borrowed
        ? 'Trả nợ: ${title ?? ''}'
        : 'Thu nợ: ${title ?? ''}';

    await _db.writeTransaction((tx) async {
      final rows = await tx.execute(
        '''INSERT INTO transactions(
             id, amount, type, category_id, note, created_at, wallet_id, source
           ) VALUES(COALESCE(?, uuid()), ?, ?, ?, ?, ?, ?, ?) RETURNING id''',
        [
          // An undo re-uses the id the deleted transaction had, so anything
          // still pointing at it lines back up.
          transactionId,
          amount.toString(),
          loanType == LoanType.borrowed ? 'expense' : 'income',
          categoryId,
          note == null || note.isEmpty ? fallbackNote.trim() : note,
          paidAt.millisecondsSinceEpoch.toString(),
          walletId,
          kLoanTransactionSource,
        ],
      );
      await tx.execute(
        '''INSERT INTO loan_payments(id, loan_id, amount, paid_at, note,
             transaction_id)
           VALUES(uuid(), ?, ?, ?, ?, ?)''',
        [
          loanId,
          amount.toString(),
          paidAt.toIso8601String(),
          note,
          rows.first['id'] as String,
        ],
      );
    });
    await _onScheduleChanged(loanId);
  }

  /// Deletes a payment and the transaction it wrote, together.
  Future<void> deletePayment(String paymentId) async {
    String? loanId;
    await _db.writeTransaction((tx) async {
      final row = await tx.getOptional(
        '''SELECT transaction_id, loan_id FROM loan_payments WHERE id = ?''',
        [paymentId],
      );
      loanId = row?['loan_id'] as String?;
      final transactionId = row?['transaction_id'] as String?;
      if (transactionId != null) {
        await tx.execute('DELETE FROM transactions WHERE id = ?', [
          transactionId,
        ]);
      }
      await tx.execute('DELETE FROM loan_payments WHERE id = ?', [paymentId]);
    });
    // Undoing a payment can un-settle an instalment, which needs its reminder
    // back.
    if (loanId != null) await _onScheduleChanged(loanId!);
  }

  /// The wallet a transaction was written against — read before a delete, so
  /// an undo can put the money back in the same place.
  Future<String?> walletOfTransaction(String transactionId) async {
    final row = await _db.getOptional(
      'SELECT wallet_id FROM transactions WHERE id = ?',
      [transactionId],
    );
    return row?['wallet_id'] as String?;
  }

  /// The loan a `source='loan'` transaction belongs to, or null when the
  /// transaction is not one of ours.
  Future<Loan?> findByTransaction(String transactionId) async {
    final row = await _db.getOptional(
      '''SELECT l.* FROM loans l
         WHERE l.funding_transaction_id = ?
            OR l.id = (SELECT loan_id FROM loan_payments
                       WHERE transaction_id = ? LIMIT 1)
         LIMIT 1''',
      [transactionId, transactionId],
    );
    return row == null ? null : Loan.fromMap(row);
  }


  // ── Summary with remaining ────────────────────────────────────────────────

  /// Stream LoanSummary tính remaining = principal - sum(payments).
  /// Reactive với cả loans lẫn loan_payments vì watch cả 2 bảng.
  Stream<LoanSummary> watchSummaryWithRemaining({bool trackingOnly = false}) {
    // Watch loans để trigger stream mỗi khi loans hoặc payments thay đổi.
    // PowerSync watch sẽ emit lại khi bất kỳ row nào trong query thay đổi.
    return _db
        .watch('''
          SELECT
            l.id,
            l.type,
            l.principal,
            l.is_closed,
            l.due_date,
            COALESCE(SUM(CAST(p.amount AS INTEGER)), 0) as total_paid
          FROM loans l
          LEFT JOIN loan_payments p ON p.loan_id = l.id
          WHERE l.is_closed = 0
            AND COALESCE(l.is_tracking_only, 0) = ?
          GROUP BY l.id, l.type, l.principal, l.is_closed, l.due_date
        ''', parameters: [trackingOnly ? 1 : 0])
        .map((rows) {
      if (rows.isEmpty) {
        return const LoanSummary(
          count: 0,
          remainingBorrowed: 0,
          remainingLent: 0,
          hasOverdue: false,
          hasUpcoming: false,
          overdueCount: 0,
          upcomingCount: 0,
        );
      }

      int remBorrowed = 0;
      int remLent = 0;
      int overdueCount = 0;
      int upcomingCount = 0;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final row in rows) {
        final principal = int.tryParse(row['principal'] as String? ?? '0') ?? 0;
        final totalPaid = row['total_paid'] as int;
        final remaining = (principal - totalPaid).clamp(0, principal);

        final type = row['type'] as String;
        if (type == LoanType.borrowed.name) {
          remBorrowed += remaining;
        } else {
          remLent += remaining;
        }

        // Tính status từ due_date
        final dueDateStr = row['due_date'] as String?;
        if (dueDateStr != null && dueDateStr.isNotEmpty) {
          final due = DateTime.tryParse(dueDateStr);
          if (due != null) {
            final dueDay = DateTime(due.year, due.month, due.day);
            final diff = dueDay.difference(today).inDays;
            if (diff < 0) {
              overdueCount++;
            } else if (diff <= 7) {
              upcomingCount++;
            }
          }
        }
      }

      return LoanSummary(
        count: rows.length,
        remainingBorrowed: remBorrowed,
        remainingLent: remLent,
        hasOverdue: overdueCount > 0,
        hasUpcoming: upcomingCount > 0,
        overdueCount: overdueCount,
        upcomingCount: upcomingCount,
      );
    });
  }
}


DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
