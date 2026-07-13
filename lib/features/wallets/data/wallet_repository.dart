import 'package:powersync/powersync.dart';

import '../../../core/db/powersync_db.dart';
import '../domain/wallet.dart';

class WalletRepository {
  WalletRepository({PowerSyncDatabase? database}) : _database = database ?? db;

  final PowerSyncDatabase _database;

  /// Stream tất cả wallet chưa archive, sắp xếp theo sort_order.
  Stream<List<Wallet>> watchAll() {
    return _database
        .watch(
          'SELECT * FROM wallets WHERE is_archived = 0 ORDER BY sort_order ASC',
        )
        .map((rows) => rows.map(Wallet.fromMap).toList());
  }

  /// Stream bao gồm cả archived (dùng trong WalletsScreen section "Đã lưu trữ").
  Stream<List<Wallet>> watchArchived() {
    return _database
        .watch(
          'SELECT * FROM wallets WHERE is_archived = 1 ORDER BY sort_order ASC',
        )
        .map((rows) => rows.map(Wallet.fromMap).toList());
  }

  Future<List<Wallet>> getAll() async {
    final rows = await _database.getAll(
      'SELECT * FROM wallets WHERE is_archived = 0 ORDER BY sort_order ASC',
    );
    return rows.map(Wallet.fromMap).toList();
  }

  Future<Wallet?> getById(String id) async {
    final row = await _database.getOptional(
      'SELECT * FROM wallets WHERE id = ?',
      [id],
    );
    return row == null ? null : Wallet.fromMap(row);
  }

  Future<void> add(Wallet w) async {
    final maxOrder = await _database.get(
      'SELECT COALESCE(MAX(sort_order), -1) as mo FROM wallets',
    );
    final nextOrder = (maxOrder['mo'] as int) + 1;

    await _database.execute(
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
    await _database.execute(
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
    await _database.execute('UPDATE wallets SET is_archived = 1 WHERE id = ?', [
      id,
    ]);
  }

  Future<void> unarchive(String id) async {
    await _database.execute('UPDATE wallets SET is_archived = 0 WHERE id = ?', [
      id,
    ]);
  }

  /// Chỉ xoá được khi không còn transaction nào gắn wallet này.
  Future<void> delete(String id) async {
    final count = await transactionCount(id);
    if (count > 0) {
      throw Exception(
        'Ví còn $count giao dịch. Hãy gỡ liên kết hoặc lưu trữ ví thay vì xoá.',
      );
    }
    await _database.execute('DELETE FROM wallets WHERE id = ?', [id]);
  }

  /// Số transaction đang gắn với wallet này.
  Future<int> transactionCount(String walletId) async {
    final row = await _database.get(
      'SELECT COUNT(*) as cnt FROM transactions WHERE wallet_id = ?',
      [walletId],
    );
    return row['cnt'] as int;
  }

  /// Trả về tổng income và expense của wallet — dùng cho breakdown providers.
  Future<({int income, int expense})> getIncomeExpense(String walletId) async {
    final row = await _database.get(
      '''SELECT
           COALESCE(SUM(CASE WHEN type = 'income' THEN CAST(amount AS INTEGER) ELSE 0 END), 0) as income,
           COALESCE(SUM(CASE WHEN type = 'expense' THEN CAST(amount AS INTEGER) ELSE 0 END), 0) as expense
         FROM transactions
         WHERE wallet_id = ?''',
      [walletId],
    );
    return (income: row['income'] as int, expense: row['expense'] as int);
  }

  /// Balance = initial_balance + tổng thu - tổng chi của wallet này.
  Future<int> calculateBalance(String walletId) async {
    final wallet = await getById(walletId);
    if (wallet == null) return 0;

    final breakdown = await getIncomeExpense(walletId);
    return wallet.initialBalance + breakdown.income - breakdown.expense;
  }

  /// Theo dõi số dư và breakdown của một ví từ cả wallets lẫn transactions.
  Stream<({int balance, int x1, int x2})> watchFinancialSummary(
    String walletId,
  ) {
    return _database
        .watch(
          '''SELECT
               CAST(w.initial_balance AS INTEGER) as initial_balance,
               COALESCE(SUM(CASE WHEN t.type = 'income' THEN CAST(t.amount AS INTEGER) ELSE 0 END), 0) as income,
               COALESCE(SUM(CASE WHEN t.type = 'expense' THEN CAST(t.amount AS INTEGER) ELSE 0 END), 0) as expense
             FROM wallets w
             LEFT JOIN transactions t ON t.wallet_id = w.id
             WHERE w.id = ?
             GROUP BY w.id, w.initial_balance''',
          parameters: [walletId],
        )
        .map((rows) {
          if (rows.isEmpty) return (balance: 0, x1: 0, x2: 0);
          final row = rows.single;
          final initial = row['initial_balance'] as int;
          final income = row['income'] as int;
          final expense = row['expense'] as int;
          return (
            balance: initial + income - expense,
            x1: initial + income,
            x2: expense,
          );
        });
  }

  /// Theo dõi tổng tài chính của mọi ví active bằng một aggregate query.
  Stream<({int balance, int x1, int x2})> watchActiveFinancialSummary() {
    return _database
        .watch('''
          WITH transaction_totals AS (
            SELECT
              wallet_id,
              COALESCE(SUM(CASE WHEN type = 'income' THEN CAST(amount AS INTEGER) ELSE 0 END), 0) as income,
              COALESCE(SUM(CASE WHEN type = 'expense' THEN CAST(amount AS INTEGER) ELSE 0 END), 0) as expense
            FROM transactions
            WHERE wallet_id IS NOT NULL
            GROUP BY wallet_id
          )
          SELECT
            COALESCE(SUM(CAST(w.initial_balance AS INTEGER) + COALESCE(t.income, 0) - COALESCE(t.expense, 0)), 0) as balance,
            COALESCE(SUM(CAST(w.initial_balance AS INTEGER) + COALESCE(t.income, 0)), 0) as x1,
            COALESCE(SUM(COALESCE(t.expense, 0)), 0) as x2
          FROM wallets w
          LEFT JOIN transaction_totals t ON t.wallet_id = w.id
          WHERE w.is_archived = 0
        ''')
        .map((rows) {
          final row = rows.single;
          return (
            balance: row['balance'] as int,
            x1: row['x1'] as int,
            x2: row['x2'] as int,
          );
        });
  }
}
