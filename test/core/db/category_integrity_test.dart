import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';
import 'package:spendo/core/db/powersync_db.dart';
import 'package:spendo/core/db/schema.dart';
import 'package:spendo/features/categories/data/category_repository.dart';
import 'package:spendo/features/categories/domain/category.dart';
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqlite_async/sqlite3_common.dart';
import 'package:sqlite_async/sqlite_async.dart';

void main() {
  late Directory tempDirectory;
  late PowerSyncDatabase database;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'spendo_category_integrity_test_',
    );
    database = PowerSyncDatabase.withFactory(
      _TestPowerSyncOpenFactory(
        path: p.join(tempDirectory.path, 'categories.db'),
        libraryPath: _powerSyncLibraryPath(),
      ),
      schema: schema,
    );
    await database.initialize();
  });

  setUp(() async {
    for (final table in const [
      'transactions',
      'recurring_reminders',
      'category_budgets',
      'detected_habits',
      'categories',
    ]) {
      await database.execute('DELETE FROM $table');
    }
  });

  tearDownAll(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  test(
    'duplicate repair remaps every category reference before deletion',
    () async {
      await database.execute('''INSERT INTO categories(
      id, name, color_hex, icon_name, is_default, is_income, sort_order
    ) VALUES
      ('custom-food', 'Ăn uống', '#111111', 'more_horiz', 0, 0, 0),
      ('default-food', 'Ăn uống', '#222222', 'restaurant', 1, 0, 1)''');
      await database.execute(
        '''INSERT INTO transactions(
      id, amount, type, category_id, note, created_at, wallet_id, source
    ) VALUES('transaction-1', '1000', 'expense', 'custom-food', NULL, '1', NULL, 'manual')''',
      );
      await database.execute('''INSERT INTO recurring_reminders(
      id, title, category_id, amount_hint, frequency, day_of_week,
      day_of_month, hour, minute, is_active, next_trigger, warn_before_hours
    ) VALUES(
      'reminder-1', 'Ăn sáng', 'custom-food', NULL, 'daily', NULL,
      NULL, 8, 0, 1, '2026-07-18T08:00:00.000', 1
    )''');
      await database.execute(
        "INSERT INTO category_budgets(id, category_id, amount) VALUES('budget-1', 'custom-food', '500000')",
      );
      await database.execute('''INSERT INTO detected_habits(
      id, keyword, category_id, median_gap_days, last_occurrence,
      occurrence_count, is_dismissed, analyzed_at
    ) VALUES(
      'habit-1', 'ăn sáng', 'custom-food', 7, '2026-07-10T00:00:00.000',
      3, 0, '2026-07-17T00:00:00.000'
    )''');

      await repairDuplicateCategories(database);

      final categories = await database.getAll(
        "SELECT id FROM categories WHERE name = 'Ăn uống' AND is_income = 0",
      );
      expect(categories, hasLength(1));
      expect(categories.single['id'], 'default-food');
      for (final table in const [
        'transactions',
        'recurring_reminders',
        'category_budgets',
        'detected_habits',
      ]) {
        final row = await database.get('SELECT category_id FROM $table');
        expect(row['category_id'], 'default-food', reason: table);
      }
    },
  );

  test(
    'repository rejects duplicate add and rename within the same type',
    () async {
      await database.execute('''INSERT INTO categories(
      id, name, color_hex, icon_name, is_default, is_income, sort_order
    ) VALUES
      ('food', 'Ăn uống', '#111111', 'restaurant', 1, 0, 0),
      ('travel', 'Di chuyển', '#222222', 'directions_car', 1, 0, 1)''');
      final repository = CategoryRepository(database: database);

      await expectLater(
        repository.add(
          name: 'Ăn uống',
          colorHex: '#333333',
          iconName: 'more_horiz',
          isIncome: false,
        ),
        throwsA(isA<DuplicateCategoryException>()),
      );
      await expectLater(
        repository.update(
          const Category(
            id: 'travel',
            name: 'Ăn uống',
            colorHex: '#222222',
            iconName: 'directions_car',
            isDefault: true,
            isIncome: false,
            sortOrder: 1,
          ),
        ),
        throwsA(isA<DuplicateCategoryException>()),
      );

      expect(await database.getAll('SELECT id FROM categories'), hasLength(2));
    },
  );

  group('delete guard', () {
    Future<void> seedCategory() => database.execute('''INSERT INTO categories(
      id, name, color_hex, icon_name, is_default, is_income, sort_order
    ) VALUES('pets', 'Thú cưng', '#111111', 'pets', 0, 0, 0)''');

    Future<void> seedReminder() => database.execute('''INSERT INTO recurring_reminders(
      id, title, category_id, amount_hint, frequency, day_of_week,
      day_of_month, hour, minute, is_active, next_trigger, warn_before_hours
    ) VALUES(
      'reminder-1', 'Cát mèo', 'pets', NULL, 'monthly', NULL,
      5, 20, 0, 1, '2026-09-05T20:00:00.000', 0
    )''');

    test('a recurring reminder blocks the delete, and is named', () async {
      // The guard used to count transactions only, so this category could go
      // and leave the reminder deep-linking into a tile that no longer existed.
      await seedCategory();
      await seedReminder();

      await expectLater(
        CategoryRepository(database: database).delete('pets'),
        throwsA(
          predicate((e) => e.toString().contains('còn 1 nhắc nhở')),
        ),
      );
      expect(await database.getAll('SELECT id FROM categories'), hasLength(1));
    });

    test('a per-category budget blocks the delete', () async {
      await seedCategory();
      await database.execute(
        "INSERT INTO category_budgets(id, category_id, amount) VALUES('budget-1', 'pets', '500000')",
      );

      await expectLater(
        CategoryRepository(database: database).delete('pets'),
        throwsA(predicate((e) => e.toString().contains('đang có hạn mức'))),
      );
      expect(await database.getAll('SELECT id FROM categories'), hasLength(1));
    });

    test('transactions are reported ahead of anything else', () async {
      await seedCategory();
      await seedReminder();
      await database.execute(
        '''INSERT INTO transactions(
      id, amount, type, category_id, note, created_at, wallet_id, source
    ) VALUES('transaction-1', '1000', 'expense', 'pets', NULL, '1', NULL, 'manual')''',
      );

      await expectLater(
        CategoryRepository(database: database).delete('pets'),
        throwsA(predicate((e) => e.toString().contains('còn 1 giao dịch'))),
      );
    });

    test('an unused category goes, and takes its habit suggestions', () async {
      await seedCategory();
      await database.execute('''INSERT INTO detected_habits(
      id, keyword, category_id, median_gap_days, last_occurrence,
      occurrence_count, is_dismissed, analyzed_at
    ) VALUES(
      'habit-1', 'cát mèo', 'pets', 30, '2026-08-01T00:00:00.000',
      3, 0, '2026-09-01T00:00:00.000'
    )''');

      await CategoryRepository(database: database).delete('pets');

      expect(await database.getAll('SELECT id FROM categories'), isEmpty);
      expect(await database.getAll('SELECT id FROM detected_habits'), isEmpty);
    });
  });
}

class _TestPowerSyncOpenFactory extends PowerSyncOpenFactory {
  _TestPowerSyncOpenFactory({required super.path, required this.libraryPath});

  final String libraryPath;

  @override
  CommonDatabase open(SqliteOpenOptions options) {
    if (Platform.isWindows) {
      sqlite_open.open.overrideFor(
        sqlite_open.OperatingSystem.windows,
        () => DynamicLibrary.open('winsqlite3.dll'),
      );
    }
    return super.open(options);
  }

  @override
  String getLibraryForPlatform({String? path}) => libraryPath;
}

String _powerSyncLibraryPath() {
  final configFile = File('.dart_tool/package_config.json');
  final config =
      jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final packages = config['packages'] as List<dynamic>;
  final package = packages.cast<Map<String, dynamic>>().singleWhere(
    (entry) => entry['name'] == 'powersync_flutter_libs',
  );
  final rootUri = configFile.uri.resolve(package['rootUri'] as String);
  final root = rootUri.toFilePath();
  if (Platform.isWindows) {
    return p.join(root, 'windows', 'powersync_x64.dll');
  }
  if (Platform.isLinux) {
    return p.join(
      root,
      'linux',
      Platform.version.contains('aarch64')
          ? 'libpowersync_aarch64.so'
          : 'libpowersync_x64.so',
    );
  }
  return p.join(root, 'macos', 'libpowersync.dylib');
}
