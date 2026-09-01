import 'package:powersync/powersync.dart';
import '../../../core/db/powersync_db.dart';
import '../../../core/utils/widget_sync.dart';
import '../domain/category.dart';

class DuplicateCategoryException implements Exception {
  const DuplicateCategoryException(this.name);

  final String name;

  @override
  String toString() => 'Danh mục "$name" đã tồn tại.';
}

class CategoryRepository {
  CategoryRepository({PowerSyncDatabase? database})
    : _database = database ?? db;

  final PowerSyncDatabase _database;

  Stream<List<Category>> watchAll() {
    return _database
        .watch(
          'SELECT * FROM categories ORDER BY is_income ASC, sort_order ASC',
        )
        .map((rows) => rows.map(Category.fromMap).toList());
  }

  Future<List<Category>> getByType({required bool isIncome}) async {
    final rows = await _database.getAll(
      'SELECT * FROM categories WHERE is_income=? ORDER BY sort_order ASC',
      [isIncome ? 1 : 0],
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Category>> getAll() async {
    final rows = await _database.getAll(
      'SELECT * FROM categories ORDER BY is_income ASC, sort_order ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  /// Tìm category theo tên và loại (thu/chi). Trả null nếu không tìm thấy.
  Future<Category?> findByName(String name, {required bool isIncome}) async {
    final rows = await _database.getAll(
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
    await _database.writeTransaction((transaction) async {
      final duplicates = await transaction.getAll(
        '''SELECT id FROM categories
           WHERE name = ? AND is_income = ?
           LIMIT 1''',
        [name, isIncome ? 1 : 0],
      );
      if (duplicates.isNotEmpty) throw DuplicateCategoryException(name);
      final maxOrder = await transaction.get(
        'SELECT COALESCE(MAX(sort_order), -1) as mo FROM categories WHERE is_income=?',
        [isIncome ? 1 : 0],
      );
      final nextOrder = (maxOrder['mo'] as int) + 1;

      await transaction.execute(
        'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
        'VALUES(uuid(), ?, ?, ?, 0, ?, ?)',
        [name, colorHex, iconName, isIncome ? 1 : 0, nextOrder],
      );
    });

    await WidgetSync.syncCategories();
  }

  Future<void> update(Category c) async {
    await _database.writeTransaction((transaction) async {
      final duplicates = await transaction.getAll(
        '''SELECT id FROM categories
           WHERE name = ? AND is_income = ? AND id != ?
           LIMIT 1''',
        [c.name, c.isIncome ? 1 : 0, c.id],
      );
      if (duplicates.isNotEmpty) throw DuplicateCategoryException(c.name);
      await transaction.execute(
        'UPDATE categories SET name=?, color_hex=?, icon_name=? WHERE id=?',
        [c.name, c.colorHex, c.iconName, c.id],
      );
    });

    await WidgetSync.syncCategories();
  }

  /// Re-inserts a deleted category with its original id and sort order.
  ///
  /// Backs the Hoàn tác on the Danh mục page: [add] mints a fresh uuid, which
  /// would orphan anything that still referenced the old one.
  Future<void> restore(Category category) async {
    await _database.execute(
      'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
      'VALUES(?, ?, ?, ?, ?, ?, ?)',
      [
        category.id,
        category.name,
        category.colorHex,
        category.iconName,
        category.isDefault ? 1 : 0,
        category.isIncome ? 1 : 0,
        category.sortOrder,
      ],
    );

    await WidgetSync.syncCategories();
  }

  /// Rewrites `sort_order` so the categories land in the given order.
  ///
  /// [orderedIds] must hold every id of one side (expense or income); the
  /// column already existed but nothing ever wrote to it after creation, so
  /// the grid in Thêm giao dịch was stuck in insertion order.
  Future<void> reorder(List<String> orderedIds) async {
    if (orderedIds.isEmpty) return;

    await _database.writeTransaction((transaction) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await transaction.execute(
          'UPDATE categories SET sort_order=? WHERE id=?',
          [i, orderedIds[i]],
        );
      }
    });

    await WidgetSync.syncCategories();
  }

  /// Number of transactions per category id, so the list can say what a
  /// category is actually holding before you try to delete it.
  Stream<Map<String, int>> watchTransactionCounts() {
    return _database
        .watch(
          'SELECT category_id, COUNT(*) as cnt FROM transactions '
          'GROUP BY category_id',
        )
        .map(
          (rows) => {
            for (final row in rows)
              row['category_id'] as String: row['cnt'] as int,
          },
        );
  }

  Future<void> delete(String id) async {
    // Không xoá nếu còn giao dịch đang dùng category này
    final usage = await _database.get(
      'SELECT COUNT(*) as cnt FROM transactions WHERE category_id=?',
      [id],
    );
    if ((usage['cnt'] as int) > 0) {
      throw Exception('Danh mục đang được sử dụng, không thể xoá.');
    }
    await _database.execute('DELETE FROM categories WHERE id=?', [id]);

    await WidgetSync.syncCategories();
  }
}
