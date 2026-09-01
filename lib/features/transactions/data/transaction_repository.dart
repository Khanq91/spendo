import 'package:powersync/powersync.dart';
import '../../../core/db/powersync_db.dart';
import '../domain/transaction.dart';

class TransactionRepository {
  TransactionRepository({PowerSyncDatabase? database})
    : _database = database ?? db;

  final PowerSyncDatabase _database;

  Stream<List<Transaction>> watchByMonth(int year, int month) {
    final start = DateTime(year, month).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1).millisecondsSinceEpoch;

    return _database
        .watch(
          'SELECT * FROM transactions '
          'WHERE created_at >= ? AND created_at < ? '
          'ORDER BY created_at DESC',
          parameters: [start.toString(), end.toString()],
        )
        .map((rows) => rows.map(Transaction.fromMap).toList());
  }

  /// Query transactions trong khoảng [start, end).
  Stream<List<Transaction>> watchByDateRange(DateTime start, DateTime end) {
    return _database
        .watch(
          'SELECT * FROM transactions '
          'WHERE created_at >= ? AND created_at < ? '
          'ORDER BY created_at DESC',
          parameters: [
            start.millisecondsSinceEpoch.toString(),
            end.millisecondsSinceEpoch.toString(),
          ],
        )
        .map((rows) => rows.map(Transaction.fromMap).toList());
  }

  Future<void> add({
    required int amount,
    required String type,
    required String categoryId,
    String? note,
    DateTime? createdAt,
    String? walletId,
    String source = 'manual',
  }) async {
    final at =
        (createdAt?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch)
            .toString();

    await _database.execute(
      'INSERT INTO transactions(id, amount, type, category_id, note, created_at, wallet_id, source) '
      'VALUES(uuid(), ?, ?, ?, ?, ?, ?, ?)',
      [amount.toString(), type, categoryId, note, at, walletId, source],
    );
  }

  Future<void> batchAdd(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final at =
          (row['createdAt'] as DateTime).millisecondsSinceEpoch.toString();
      await _database.execute(
        'INSERT INTO transactions(id, amount, type, category_id, note, created_at, wallet_id, source) '
        'VALUES(uuid(), ?, ?, ?, ?, ?, ?, ?)',
        [
          (row['amount'] as int).toString(),
          row['type'] as String,
          row['categoryId'] as String,
          row['note'] as String?,
          at,
          row['walletId'] as String?,
          row['source'] as String? ?? 'manual',
        ],
      );
    }
  }

  Future<List<Transaction>> getAll() async {
    final rows = await _database.getAll(
      'SELECT * FROM transactions ORDER BY created_at DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Future<void> update(Transaction t) async {
    await _database.execute(
      'UPDATE transactions SET amount=?, type=?, category_id=?, note=?, '
      'created_at=?, wallet_id=?, source=? WHERE id=?',
      [
        t.amount.toString(),
        t.type,
        t.categoryId,
        t.note,
        t.createdAt.millisecondsSinceEpoch.toString(),
        t.walletId,
        t.source,
        t.id,
      ],
    );
  }

  Future<void> delete(String id) async {
    await _database.execute('DELETE FROM transactions WHERE id=?', [id]);
  }

  Future<List<Transaction>> getRange({DateTime? from}) async {
    if (from == null) {
      final rows = await _database.getAll(
        'SELECT * FROM transactions ORDER BY created_at DESC',
      );
      return rows.map(Transaction.fromMap).toList();
    }
    final rows = await _database.getAll(
      'SELECT * FROM transactions WHERE created_at >= ? ORDER BY created_at DESC',
      [from.millisecondsSinceEpoch.toString()],
    );
    return rows.map(Transaction.fromMap).toList();
  }

  /// Transactions của 1 wallet trong 1 tháng cụ thể.
  Future<List<Transaction>> getByWalletAndMonth(
    String walletId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1).millisecondsSinceEpoch;
    final rows = await _database.getAll(
      'SELECT * FROM transactions '
      'WHERE wallet_id = ? AND created_at >= ? AND created_at < ? '
      'ORDER BY created_at DESC',
      [walletId, start.toString(), end.toString()],
    );
    return rows.map(Transaction.fromMap).toList();
  }

  /// Toàn bộ transactions của 1 wallet.
  Future<List<Transaction>> getByWallet(String walletId) async {
    final rows = await _database.getAll(
      'SELECT * FROM transactions WHERE wallet_id = ? ORDER BY created_at DESC',
      [walletId],
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Stream<List<Transaction>> watchByWalletAndMonth(
    String walletId,
    int year,
    int month,
  ) {
    final start = DateTime(year, month).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1).millisecondsSinceEpoch;
    return _database
        .watch(
          'SELECT * FROM transactions '
          'WHERE wallet_id = ? AND created_at >= ? AND created_at < ? '
          'ORDER BY created_at DESC',
          parameters: [walletId, start.toString(), end.toString()],
        )
        .map((rows) => rows.map(Transaction.fromMap).toList());
  }

  Stream<List<Transaction>> watchByWallet(String walletId) {
    return _database
        .watch(
          'SELECT * FROM transactions WHERE wallet_id = ? ORDER BY created_at DESC',
          parameters: [walletId],
        )
        .map((rows) => rows.map(Transaction.fromMap).toList());
  }
}
