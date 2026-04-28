import 'package:uuid/uuid.dart';
import '../../../core/db/powersync_db.dart';
import '../domain/transaction.dart';

const _uuid = Uuid();

class TransactionRepository {
  Stream<List<Transaction>> watchByMonth(int year, int month) {
    final start = DateTime(year, month).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1).millisecondsSinceEpoch;

    return db
        .watch(
      'SELECT * FROM transactions '
          'WHERE created_at >= ? AND created_at < ? '
          'ORDER BY created_at DESC',
      parameters: [start.toString(), end.toString()],
    )
        .map((rows) => rows.map(Transaction.fromMap).toList());
  }

  Future<void> add({
    required int amount,
    required String type,
    required String categoryId,
    String? note,
    DateTime? createdAt,
  }) async {
    final at = (createdAt?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch)
        .toString();

    await db.execute(
      'INSERT INTO transactions(id, amount, type, category_id, note, created_at) '
          'VALUES(uuid(), ?, ?, ?, ?, ?)',
      [amount.toString(), type, categoryId, note, at],
    );
  }

  Future<void> update(Transaction t) async {
    // Không ghi updated_at thủ công — PowerSync tự quản lý field này
    await db.execute(
      'UPDATE transactions SET amount=?, type=?, category_id=?, note=? WHERE id=?',
      [t.amount.toString(), t.type, t.categoryId, t.note, t.id],
    );
  }

  Future<void> delete(String id) async {
    await db.execute('DELETE FROM transactions WHERE id=?', [id]);
  }

  Future<List<Transaction>> getRange({DateTime? from}) async {
    if (from == null) {
      final rows = await db.getAll(
        'SELECT * FROM transactions ORDER BY created_at DESC',
      );
      return rows.map(Transaction.fromMap).toList();
    }
    final rows = await db.getAll(
      'SELECT * FROM transactions WHERE created_at >= ? ORDER BY created_at DESC',
      [from.millisecondsSinceEpoch.toString()],
    );
    return rows.map(Transaction.fromMap).toList();
  }
}