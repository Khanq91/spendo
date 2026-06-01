import '../../../core/db/powersync_db.dart';
import '../domain/wallet.dart';

class WalletRepository {
  /// Stream tất cả wallet chưa archive, sắp xếp theo sort_order.
  Stream<List<Wallet>> watchAll() {
    return db
        .watch(
      'SELECT * FROM wallets WHERE is_archived = 0 ORDER BY sort_order ASC',
    )
        .map((rows) => rows.map(Wallet.fromMap).toList());
  }

  /// Stream bao gồm cả archived (dùng trong WalletsScreen section "Đã lưu trữ").
  Stream<List<Wallet>> watchArchived() {
    return db
        .watch(
      'SELECT * FROM wallets WHERE is_archived = 1 ORDER BY sort_order ASC',
    )
        .map((rows) => rows.map(Wallet.fromMap).toList());
  }

  Future<List<Wallet>> getAll() async {
    final rows = await db.getAll(
      'SELECT * FROM wallets WHERE is_archived = 0 ORDER BY sort_order ASC',
    );
    return rows.map(Wallet.fromMap).toList();
  }

  Future<Wallet?> getById(String id) async {
    final row = await db.getOptional(
      'SELECT * FROM wallets WHERE id = ?',
      [id],
    );
    return row == null ? null : Wallet.fromMap(row);
  }

  Future<void> add(Wallet w) async {
    final maxOrder = await db.get(
      'SELECT COALESCE(MAX(sort_order), -1) as mo FROM wallets',
    );
    final nextOrder = (maxOrder['mo'] as int) + 1;

    await db.execute(
      '''INSERT INTO wallets(id, name, type, initial_balance, note, color_hex, sort_order, is_archived)
         VALUES(uuid(), ?, ?, ?, ?, ?, ?, 0)''',
      [
        w.name,
        w.type.name,
        w.initialBalance.toString(),
        w.note,
        w.colorHex,
        nextOrder,
      ],
    );
  }

  Future<void> update(Wallet w) async {
    await db.execute(
      '''UPDATE wallets SET name=?, type=?, initial_balance=?, note=?, color_hex=?
         WHERE id=?''',
      [
        w.name,
        w.type.name,
        w.initialBalance.toString(),
        w.note,
        w.colorHex,
        w.id,
      ],
    );
  }

  Future<void> archive(String id) async {
    await db.execute(
      'UPDATE wallets SET is_archived = 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> unarchive(String id) async {
    await db.execute(
      'UPDATE wallets SET is_archived = 0 WHERE id = ?',
      [id],
    );
  }

  /// Chỉ xoá được khi không còn transaction nào gắn wallet này.
  Future<void> delete(String id) async {
    final count = await transactionCount(id);
    if (count > 0) {
      throw Exception(
        'Ví còn $count giao dịch. Hãy gỡ liên kết hoặc lưu trữ ví thay vì xoá.',
      );
    }
    await db.execute('DELETE FROM wallets WHERE id = ?', [id]);
  }

  /// Số transaction đang gắn với wallet này.
  Future<int> transactionCount(String walletId) async {
    final row = await db.get(
      'SELECT COUNT(*) as cnt FROM transactions WHERE wallet_id = ?',
      [walletId],
    );
    return row['cnt'] as int;
  }

  /// Trả về tổng income và expense của wallet — dùng cho breakdown providers.
  Future<({int income, int expense})> getIncomeExpense(String walletId) async {
    final row = await db.get(
      '''SELECT
           COALESCE(SUM(CASE WHEN type = 'income' THEN CAST(amount AS INTEGER) ELSE 0 END), 0) as income,
           COALESCE(SUM(CASE WHEN type = 'expense' THEN CAST(amount AS INTEGER) ELSE 0 END), 0) as expense
         FROM transactions
         WHERE wallet_id = ?''',
      [walletId],
    );
    return (
    income: row['income'] as int,
    expense: row['expense'] as int,
    );
  }

  /// Balance = initial_balance + tổng thu - tổng chi của wallet này.
  Future<int> calculateBalance(String walletId) async {
    final wallet = await getById(walletId);
    if (wallet == null) return 0;

    final breakdown = await getIncomeExpense(walletId);
    return wallet.initialBalance + breakdown.income - breakdown.expense;
  }
}