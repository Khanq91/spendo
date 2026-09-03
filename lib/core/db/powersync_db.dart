import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'powersync_connector.dart';
import 'schema.dart';

late final PowerSyncDatabase db;

@visibleForTesting
void initializeDatabaseForTesting(PowerSyncDatabase database) {
  db = database;
}

Future<void> openDatabase({
  String databaseName = 'spendo.db',
  bool setupSync = true,
}) async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, databaseName);

  db = PowerSyncDatabase(schema: schema, path: dbPath);

  await db.initialize();

  // `wallet_id` and `source` used to be added here with ALTER TABLE, swallowed
  // when it failed. It always failed: PowerSync exposes the tables as views,
  // and both columns come from `schema.dart` anyway.

  await repairDuplicateCategories();
  if (setupSync) {
    await _setupSync();
  }
  await _seedDefaultCategoriesIfNeeded(db);
}

/// Wipes every local table — synced and local-only alike — and puts the
/// default categories back, so the app starts over as on first install.
/// The database stays open; the caller resets the rest of the app around it.
Future<void> resetLocalDatabase([PowerSyncDatabase? database]) async {
  final target = database ?? db;
  await target.disconnectAndClear();
  await _seedDefaultCategoriesIfNeeded(target);
}

Future<void> repairDuplicateCategories([PowerSyncDatabase? database]) async {
  final target = database ?? db;
  await target.writeTransaction((transaction) async {
    await repairDuplicateCategoriesInTransaction(
      readRows: (sql, parameters) => transaction.getAll(sql, parameters),
      execute: (sql, parameters) => transaction.execute(sql, parameters),
    );
  });
}

Future<void> repairDuplicateCategoriesInTransaction({
  required Future<List<Map<String, dynamic>>> Function(
    String sql,
    List<Object?> parameters,
  )
  readRows,
  required Future<void> Function(String sql, List<Object?> parameters) execute,
}) async {
  final groups = await readRows('''
      SELECT name, is_income
      FROM categories
      GROUP BY name, is_income
      HAVING COUNT(*) > 1
    ''', const []);

  for (final group in groups) {
    final categories = await readRows(
      '''SELECT id
           FROM categories
           WHERE name = ? AND is_income = ?
           ORDER BY is_default DESC, sort_order ASC, id ASC''',
      [group['name'], group['is_income']],
    );
    final canonicalId = categories.first['id'] as String;

    for (final duplicate in categories.skip(1)) {
      final duplicateId = duplicate['id'] as String;
      for (final table in const [
        'transactions',
        'recurring_reminders',
        'category_budgets',
        'detected_habits',
      ]) {
        await execute(
          'UPDATE $table SET category_id = ? WHERE category_id = ?',
          [canonicalId, duplicateId],
        );
      }
      await execute('DELETE FROM categories WHERE id = ?', [duplicateId]);
    }
  }
}

Future<void> _setupSync() async {
  final session = Supabase.instance.client.auth.currentSession;

  if (session != null && session.user.id.isNotEmpty) {
    await db.connect(connector: SupabasePowerSyncConnector(db));
  }

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    if (event == AuthChangeEvent.signedIn && session != null) {
      await db.connect(connector: SupabasePowerSyncConnector(db));
    } else if (event == AuthChangeEvent.signedOut) {
      await db.disconnect();
    } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
      await db.connect(connector: SupabasePowerSyncConnector(db));
    }
  });
}

// Both seed helpers take the database as `db`, shadowing the global, so the
// same code serves the app's database and a test fixture.
Future<void> _seedDefaultCategoriesIfNeeded(PowerSyncDatabase db) async {
  final sentinel = await db.getOptional(
    "SELECT id FROM categories WHERE icon_name = 'restaurant' AND is_default = 1 LIMIT 1",
  );
  if (sentinel != null) return;

  await _seedOfflineCategories(db);
}

Future<void> _seedOfflineCategories(PowerSyncDatabase db) async {
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
    batch.add(
      db.execute(
        'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
        'VALUES(uuid(), ?, ?, ?, 1, 0, ?)',
        [c.$1, c.$2, c.$3, c.$4],
      ),
    );
  }
  for (final c in incomeCategories) {
    batch.add(
      db.execute(
        'INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order) '
        'VALUES(uuid(), ?, ?, ?, 1, 1, ?)',
        [c.$1, c.$2, c.$3, c.$4],
      ),
    );
  }
  await Future.wait(batch);
}

