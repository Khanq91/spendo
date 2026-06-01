import '../../../core/db/powersync_db.dart';
import '../domain/loan.dart';

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
}