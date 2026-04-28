import 'package:uuid/uuid.dart';
import '../../../core/db/powersync_db.dart';
import '../../../core/utils/widget_sync.dart';
import '../domain/category.dart';

const _uuid = Uuid();

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


  Future<List<Category>> getAll() async {
    final rows = await db.getAll(
      'SELECT * FROM categories ORDER BY is_income ASC, sort_order ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  /// Tìm category theo tên và loại (thu/chi). Trả null nếu không tìm thấy.
  Future<Category?> findByName(String name, {required bool isIncome}) async {
    final rows = await db.getAll(
      'SELECT * FROM categories WHERE name=? AND is_income=? LIMIT 1',
      [name, isIncome ? 1 : 0],
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<void> add({
    required String name,
    required String colorHex,
    required String iconName,
    required bool isIncome,
  }) async {
    final maxOrder = await db.get(
      'SELECT COALESCE(MAX(sort_order), -1) as mo FROM categories WHERE is_income=?',
      [isIncome ? 1 : 0],
    );
    final nextOrder = (maxOrder['mo'] as int) + 1;

    await db.execute(
      'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
          'VALUES(uuid(), ?, ?, ?, 0, ?, ?)',
      [name, colorHex, iconName, isIncome ? 1 : 0, nextOrder],
    );

    await WidgetSync.syncCategories();
  }

  Future<void> update(Category c) async {
    await db.execute(
      'UPDATE categories SET name=?, color_hex=?, icon_name=? WHERE id=?',
      [c.name, c.colorHex, c.iconName, c.id],
    );

    await WidgetSync.syncCategories();
  }

  Future<void> delete(String id) async {
    // Không xoá nếu còn giao dịch đang dùng category này
    final usage = await db.get(
      'SELECT COUNT(*) as cnt FROM transactions WHERE category_id=?',
      [id],
    );
    if ((usage['cnt'] as int) > 0) {
      throw Exception('Danh mục đang được sử dụng, không thể xoá.');
    }
    await db.execute('DELETE FROM categories WHERE id=?', [id]);

    await WidgetSync.syncCategories();
  }
}