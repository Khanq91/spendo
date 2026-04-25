import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'schema.dart';

late final PowerSyncDatabase db;

Future<void> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'spendo.db');

  db = PowerSyncDatabase(
    schema: schema,
    path: dbPath,
  );
  await db.initialize();
  await _seedDefaultCategories();
}

/// Seed categories mặc định nếu chưa có.
Future<void> _seedDefaultCategories() async {
  final existing = await db.get('SELECT COUNT(*) as cnt FROM categories');
  if ((existing['cnt'] as int) > 0) return;

  final expenseCategories = [
    ('Ăn uống', '#FF6B6B', 'restaurant', 0),
    ('Di chuyển', '#4ECDC4', 'directions_car', 1),
    ('Học tập', '#45B7D1', 'school', 2),
    ('Giải trí', '#96CEB4', 'sports_esports', 3),
    ('Sức khoẻ', '#FFEAA7', 'favorite', 4),
    ('Mua sắm', '#DDA0DD', 'shopping_bag', 5),
    ('Khác', '#B0BEC5', 'more_horiz', 6),
  ];
  final incomeCategories = [
    ('Lương', '#66BB6A', 'work', 0),
    ('Freelance', '#42A5F5', 'laptop', 1),
    ('Bán hàng', '#FFA726', 'storefront', 2),
    ('Quà tặng', '#EC407A', 'card_giftcard', 3),
    ('Khác', '#B0BEC5', 'more_horiz', 4),
  ];

  final batch = <Future>[];

  for (final c in expenseCategories) {
    batch.add(db.execute(
      'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
          'VALUES(uuid(), ?, ?, ?, 1, 0, ?)',
      [c.$1, c.$2, c.$3, c.$4],
    ));
  }
  for (final c in incomeCategories) {
    batch.add(db.execute(
      'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
          'VALUES(uuid(), ?, ?, ?, 1, 1, ?)',
      [c.$1, c.$2, c.$3, c.$4],
    ));
  }

  await Future.wait(batch);
}