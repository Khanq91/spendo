import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';
import 'package:spendo/core/db/powersync_db.dart';
import 'package:spendo/core/db/schema.dart';
import 'package:spendo/core/services/reset_data_service.dart';
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqlite_async/sqlite3_common.dart';
import 'package:sqlite_async/sqlite_async.dart';

void main() {
  group('run', () {
    test('clears in an order where nothing can re-create data behind it', () async {
      final log = <String>[];
      ResetStep step(String name) => () async => log.add(name);

      await ResetDataService(
        cancelBackgroundTasks: step('background'),
        cancelNotifications: step('notifications'),
        signOutDrive: step('drive'),
        clearDatabase: step('database'),
        clearPreferences: step('preferences'),
        clearTemporaryFiles: step('temp'),
        syncWidgets: step('widgets'),
      ).run();

      expect(log, [
        'background',
        'notifications',
        'drive',
        'database',
        'preferences',
        'temp',
        'widgets',
      ]);
    });

    test('a failing side step is logged and the rest still runs', () async {
      final log = <String>[];
      ResetStep step(String name) => () async => log.add(name);

      await ResetDataService(
        cancelBackgroundTasks: step('background'),
        cancelNotifications: () async => throw StateError('no plugin'),
        signOutDrive: step('drive'),
        clearDatabase: step('database'),
        clearPreferences: step('preferences'),
        clearTemporaryFiles: step('temp'),
        syncWidgets: step('widgets'),
      ).run();

      expect(log, [
        'background',
        'drive',
        'database',
        'preferences',
        'temp',
        'widgets',
      ]);
    });

    test('a failing database step aborts and rethrows', () async {
      final log = <String>[];
      ResetStep step(String name) => () async => log.add(name);

      final service = ResetDataService(
        cancelBackgroundTasks: step('background'),
        cancelNotifications: step('notifications'),
        signOutDrive: step('drive'),
        clearDatabase: () async => throw StateError('locked'),
        clearPreferences: step('preferences'),
        clearTemporaryFiles: step('temp'),
        syncWidgets: step('widgets'),
      );

      await expectLater(service.run(), throwsStateError);
      // Nothing after the database is touched: the user's data is intact and
      // so are their preferences, which is what a retry expects.
      expect(log, ['background', 'notifications', 'drive']);
    });
  });

  group('database', () {
    late Directory tempDirectory;
    late PowerSyncDatabase database;

    setUpAll(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'spendo_reset_test_',
      );
      database = PowerSyncDatabase.withFactory(
        _TestPowerSyncOpenFactory(
          path: p.join(tempDirectory.path, 'reset.db'),
          libraryPath: _powerSyncLibraryPath(),
        ),
        schema: schema,
      );
      await database.initialize();
      initializeDatabaseForTesting(database);
    });

    tearDownAll(() async {
      await database.close();
      await tempDirectory.delete(recursive: true);
    });

    test('summarize counts what will go; reset leaves only the defaults', () async {
      await database.execute('''INSERT INTO categories(
        id, name, color_hex, icon_name, is_default, is_income, sort_order
      ) VALUES('cat-default', 'Ăn uống', '#FF6B6B', 'restaurant', 1, 0, 0)''');
      await database.execute('''INSERT INTO categories(
        id, name, color_hex, icon_name, is_default, is_income, sort_order
      ) VALUES('cat-custom', 'Mèo', '#000000', 'pets', 0, 0, 1)''');
      for (var i = 0; i < 3; i++) {
        await database.execute(
          "INSERT INTO transactions(id) VALUES('tx-$i')",
        );
      }
      await database.execute('''INSERT INTO wallets(
        id, name, type, initial_balance, note, color_hex, sort_order, is_archived
      ) VALUES('wallet-1', 'Ví', 'cash', '0', NULL, '#000000', 0, 0)''');
      await database.execute('''INSERT INTO loans(
        id, title, type, principal, contact_name, start_date, due_date,
        note, color_hex, is_closed, repayment_mode
      ) VALUES('loan-1', 'Vay', 'borrowed', '1', 'An',
        '2026-09-01T00:00:00.000', NULL, NULL, '#123456', 0, 'lump_sum')''');
      await database.execute(
        "INSERT INTO recurring_reminders(id) VALUES('rem-1')",
      );
      await database.execute(
        "INSERT INTO budgets(id, amount, month) VALUES('b-1', '1', '2026-09')",
      );
      await database.execute(
        "INSERT INTO category_budgets(id) VALUES('cb-1')",
      );

      final before = await ResetDataService.summarize(database);
      expect(before.transactions, 3);
      expect(before.wallets, 1);
      expect(before.loans, 1);
      expect(before.reminders, 1);
      expect(before.customCategories, 1);
      expect(before.budgets, 2);

      await resetLocalDatabase(database);

      final after = await ResetDataService.summarize(database);
      expect(after.transactions, 0);
      expect(after.wallets, 0);
      expect(after.loans, 0);
      expect(after.reminders, 0);
      expect(after.customCategories, 0);
      expect(after.budgets, 0);

      // First-install state: the 12 default categories are back, the custom
      // one and the original default row are gone.
      final categories = await database.getAll(
        'SELECT name, is_default FROM categories ORDER BY name',
      );
      expect(categories.length, 12);
      expect(categories.every((row) => row['is_default'] == 1), isTrue);
      expect(categories.any((row) => row['name'] == 'Mèo'), isFalse);
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
    final fileName = Abi.current() == Abi.linuxArm64
        ? 'libpowersync_aarch64.so'
        : 'libpowersync_x64.so';
    return p.join(root, 'linux', fileName);
  }
  throw UnsupportedError(
    'PowerSync DB fixture chưa hỗ trợ ${Platform.operatingSystem}',
  );
}
