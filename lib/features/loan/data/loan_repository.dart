import '../../../core/db/powersync_db.dart';
import '../domain/loan.dart';
import '../presentation/providers/loan_provider.dart';

class LoanRepository {
  // ── Loans ────────────────────────────────────────────────────────────────

  Stream<List<Loan>> watchAll() {
    return db
        .watch('SELECT * FROM loans ORDER BY is_closed ASC, start_date DESC')
        .map((rows) => rows.map(Loan.fromMap).toList());
  }

  Future<List<Loan>> getAll() async {
    final rows = await db.getAll(
      'SELECT * FROM loans ORDER BY is_closed ASC, start_date DESC',
    );
    return rows.map(Loan.fromMap).toList();
  }

  Future<void> add(Loan loan) async {
    await db.execute(
      '''INSERT INTO loans(id, title, type, principal, contact_name,
           start_date, due_date, note, color_hex, is_closed)
         VALUES(uuid(), ?, ?, ?, ?, ?, ?, ?, ?, 0)''',
      [
        loan.title,
        loan.type.name,
        loan.principal.toString(),
        loan.contactName,
        loan.startDate.toIso8601String(),
        loan.dueDate?.toIso8601String(),
        loan.note,
        loan.colorHex,
      ],
    );
  }

  Future<void> update(Loan loan) async {
    await db.execute(
      '''UPDATE loans SET title=?, type=?, principal=?, contact_name=?,
           start_date=?, due_date=?, note=?, color_hex=?, is_closed=?
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
        loan.id,
      ],
    );
  }

  Future<void> close(String id) async {
    await db.execute(
      'UPDATE loans SET is_closed = 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> reopen(String id) async {
    await db.execute(
      'UPDATE loans SET is_closed = 0 WHERE id = ?',
      [id],
    );
  }

  Future<void> delete(String id) async {
    await db.execute('DELETE FROM loan_payments WHERE loan_id = ?', [id]);
    await db.execute('DELETE FROM loans WHERE id = ?', [id]);
  }

  // ── Payments ──────────────────────────────────────────────────────────────

  Stream<List<LoanPayment>> watchPayments(String loanId) {
    return db
        .watch(
      'SELECT * FROM loan_payments WHERE loan_id = ? ORDER BY paid_at DESC',
      parameters: [loanId],
    )
        .map((rows) => rows.map(LoanPayment.fromMap).toList());
  }

  Future<int> getTotalPaid(String loanId) async {
    final row = await db.get(
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
    await db.execute(
      '''INSERT INTO loan_payments(id, loan_id, amount, paid_at, note)
         VALUES(uuid(), ?, ?, ?, ?)''',
      [loanId, amount.toString(), paidAt.toIso8601String(), note],
    );
  }

  Future<void> deletePayment(String paymentId) async {
    await db.execute(
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
    return db
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