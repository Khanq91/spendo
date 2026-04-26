import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'powersync_connector.dart';
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

  await _deduplicateCategories();
  await _setupSync();
  await _seedDefaultCategoriesIfNeeded();
}

Future<void> _deduplicateCategories() async {
  await db.execute('''
    DELETE FROM categories
    WHERE id NOT IN (
      SELECT MIN(id)
      FROM categories
      GROUP BY name, is_income
    )
  ''');
}

Future<void> _setupSync() async {
  final session = Supabase.instance.client.auth.currentSession;

  // Chỉ connect nếu đã có session hợp lệ
  if (session != null && session.user.id.isNotEmpty) {
    await db.connect(connector: SupabasePowerSyncConnector(db));
  }

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    if (event == AuthChangeEvent.signedIn && session != null) {
      await db.connect(connector: SupabasePowerSyncConnector(db));
      // Nếu user mới (chưa có categories trên cloud) thì migrate local data lên
      await _migrateLocalDataIfNeeded(session.user.id);
    } else if (event == AuthChangeEvent.signedOut) {
      await db.disconnect();
    } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
      await db.connect(connector: SupabasePowerSyncConnector(db));
    }
  });
}

Future<void> _seedDefaultCategoriesIfNeeded() async {
  final sentinel = await db.getOptional(
    "SELECT id FROM categories WHERE icon_name = 'restaurant' AND is_default = 1 LIMIT 1",
  );
  if (sentinel != null) return;

  await _seedOfflineCategories();
}

Future<void> _seedOfflineCategories() async {
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

Future<void> _migrateLocalDataIfNeeded(String userId) async {
  // Đợi sync chạy 2 giây, check xem cloud đã có categories chưa
  await Future.delayed(const Duration(seconds: 2));

  final cloudCats = await db.getAll(
    'SELECT id FROM categories WHERE id IS NOT NULL LIMIT 1',
  );

  // Nếu đã có data từ cloud thì không làm gì
  if (cloudCats.isNotEmpty) return;

  // Không có data trên cloud → update local categories thêm user_id
  // để PowerSync upload lên Supabase
  final localCats = await db.getAll('SELECT id FROM categories');
  for (final cat in localCats) {
    await db.execute(
      'UPDATE categories SET is_default = is_default WHERE id = ?',
      [cat['id']],
    );
  }
}