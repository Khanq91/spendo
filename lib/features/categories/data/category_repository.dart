import '../../../core/db/powersync_db.dart';
import '../../transactions/domain/category.dart';

class CategoryRepository {
  Stream<List<Category>> watchAll() {
    return db
        .watch('SELECT * FROM categories ORDER BY is_income ASC, sort_order ASC')
        .map((rows) => rows.map(Category.fromMap).toList());
  }

  Future<List<Category>> getByType({required bool isIncome}) async {
    final rows = await db.getAll(
      'SELECT * FROM categories WHERE is_income=? ORDER BY sort_order ASC',
      [isIncome ? 1 : 0],
    );
    return rows.map(Category.fromMap).toList();
  }
}