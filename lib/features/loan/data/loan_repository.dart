import 'package:powersync/powersync.dart';

import '../../../core/db/powersync_db.dart' as app_db;
import '../domain/loan.dart';
import '../presentation/providers/loan_provider.dart';

class LoanRepository {
  /// Defaults to the app database; tests hand in their own.
  LoanRepository({PowerSyncDatabase? database}) : _database = database;

  final PowerSyncDatabase? _database;

  PowerSyncDatabase get _db => _database ?? app_db.db;

  // ── Loans ────────────────────────────────────────────────────────────────

  Stream<List<Loan>> watchAll() {
    return _db
        .watch('SELECT * FROM loans ORDER BY is_closed ASC, start_date DESC')
        .map((rows) => rows.map(Loan.fromMap).toList());
  }

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
  Future<String> add(Loan loan) async {
    // `RETURNING` has to run on a write connection: reading it back with a
    // plain `get` lands on the read pool, where the insert is rejected.
    final rows = await _db.execute(
      '''INSERT INTO loans(id, title, type, principal, contact_name,
           start_date, due_date, note, color_hex, is_closed, repayment_mode,
           funding_transaction_id)
         VALUES(uuid(), ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?) RETURNING id''',
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
      ],
    );
    return rows.first['id'] as String;
  }

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
  }

  Future<void> reopen(String id) async {
    await _db.execute(
      'UPDATE loans SET is_closed = 0 WHERE id = ?',
      [id],
    );
  }

  Future<void> delete(String id) async {
    await _db.writeTransaction((tx) async {
      await tx.execute('DELETE FROM loan_installments WHERE loan_id = ?', [id]);
      await tx.execute('DELETE FROM loan_payments WHERE loan_id = ?', [id]);
      await tx.execute('DELETE FROM loans WHERE id = ?', [id]);
    });
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

  Future<void> addPayment({
    required String loanId,
    required int amount,
    required DateTime paidAt,
    String? note,
  }) async {
    await _db.execute(
      '''INSERT INTO loan_payments(id, loan_id, amount, paid_at, note)
         VALUES(uuid(), ?, ?, ?, ?)''',
      [loanId, amount.toString(), paidAt.toIso8601String(), note],
    );
  }

  Future<void> deletePayment(String paymentId) async {
    await _db.execute(
      'DELETE FROM loan_payments WHERE id = ?',
      [paymentId],
    );
  }

  // ── Summary with remaining ────────────────────────────────────────────────

  /// Stream LoanSummary tính remaining = principal - sum(payments).
  /// Reactive với cả loans lẫn loan_payments vì watch cả 2 bảng.
  Stream<LoanSummary> watchSummaryWithRemaining() {
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
          GROUP BY l.id, l.type, l.principal, l.is_closed, l.due_date
        ''')
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
