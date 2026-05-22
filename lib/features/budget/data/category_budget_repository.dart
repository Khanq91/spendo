import '../../../core/db/powersync_db.dart';
import '../domain/category_budget.dart';

class CategoryBudgetRepository {
  /// Stream toàn bộ category budgets — dùng cho realtime UI update
  Stream<List<CategoryBudget>> watchAll() {
    return db
        .watch('SELECT * FROM category_budgets')
        .map((rows) => rows.map(CategoryBudget.fromMap).toList());
  }

  Future<List<CategoryBudget>> getAll() async {
    final rows = await db.getAll('SELECT * FROM category_budgets');
    return rows.map(CategoryBudget.fromMap).toList();
  }

  Future<CategoryBudget?> getByCategory(String categoryId) async {
    final row = await db.getOptional(
      'SELECT * FROM category_budgets WHERE category_id = ? LIMIT 1',
      [categoryId],
    );
    return row == null ? null : CategoryBudget.fromMap(row);
  }

  /// Upsert: nếu đã có thì update, chưa có thì insert
  Future<void> set(String categoryId, int amount) async {
    final existing = await db.getOptional(
      'SELECT id FROM category_budgets WHERE category_id = ?',
      [categoryId],
    );

    if (existing != null) {
      await db.execute(
        'UPDATE category_budgets SET amount = ? WHERE category_id = ?',
        [amount.toString(), categoryId],
      );
    } else {
      await db.execute(
        'INSERT INTO category_budgets(id, category_id, amount) VALUES(uuid(), ?, ?)',
        [categoryId, amount.toString()],
      );
    }
  }

  Future<void> delete(String categoryId) async {
    await db.execute(
      'DELETE FROM category_budgets WHERE category_id = ?',
      [categoryId],
    );
  }
}