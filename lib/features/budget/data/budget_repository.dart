import 'package:uuid/uuid.dart';
import '../../../core/db/powersync_db.dart';
import '../domain/budget.dart';

const _uuid = Uuid();

class BudgetRepository {
  Stream<Budget?> watchMonth(String monthKey) {
    return db
        .watch(
      'SELECT * FROM budgets WHERE month = ? LIMIT 1',
      parameters: [monthKey],
    )
        .map((rows) => rows.isEmpty ? null : Budget.fromMap(rows.first));
  }

  Future<void> set(String monthKey, int amount) async {
    final existing = await db.getOptional(
      'SELECT id FROM budgets WHERE month = ?',
      [monthKey],
    );

    if (existing != null) {
      await db.execute(
        'UPDATE budgets SET amount = ? WHERE month = ?',
        [amount.toString(), monthKey],
      );
    } else {
      await db.execute(
        'INSERT INTO budgets(id, amount, month) VALUES(uuid(), ?, ?)',
        [amount.toString(), monthKey],
      );
    }
  }

  Future<void> delete(String monthKey) async {
    await db.execute('DELETE FROM budgets WHERE month = ?', [monthKey]);
  }
}