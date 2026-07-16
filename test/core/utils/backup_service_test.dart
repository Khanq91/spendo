import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';
import 'package:spendo/core/db/powersync_db.dart';
import 'package:spendo/core/db/schema.dart';
import 'package:spendo/core/utils/backup_service.dart';
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqlite_async/sqlite3_common.dart';
import 'package:sqlite_async/sqlite_async.dart';

void main() {
  late Directory tempDirectory;
  late PowerSyncDatabase database;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'spendo_backup_test_',
    );
    database = PowerSyncDatabase.withFactory(
      _TestPowerSyncOpenFactory(
        path: p.join(tempDirectory.path, 'backup.db'),
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

  test('backup v4 round-trip preserves local financial data', () async {
    await database.execute(
      '''INSERT INTO wallets(
           id, name, type, initial_balance, note, color_hex, sort_order, is_archived
         ) VALUES('wallet-archived', 'Ví cũ', 'cash', '500000', NULL, '#000000', 0, 1)''',
    );
    await database.execute(
      "INSERT INTO budgets(id, amount, month) VALUES('budget-1', '3000000', '2026-07')",
    );
    await database.execute('''INSERT INTO loans(
           id, title, type, principal, contact_name, start_date, due_date,
           note, color_hex, is_closed
         ) VALUES(
           'loan-1', 'Khoản vay', 'borrowed', '1000000', 'An',
           '2026-07-01T00:00:00.000', NULL, NULL, '#123456', 0
         )''');
    await database.execute(
      '''INSERT INTO loan_payments(id, loan_id, amount, paid_at, note)
         VALUES(
           'payment-1', 'loan-1', '250000',
           '2026-07-10T00:00:00.000', 'Đợt 1'
         )''',
    );

    final jsonString = await BackupService.exportBackupAsString();
    final payload = jsonDecode(jsonString) as Map<String, dynamic>;

    expect(payload['version'], 4);
    expect((payload['wallets'] as List).single['is_archived'], isTrue);
    expect((payload['budgets'] as List).single['month'], '2026-07');
    expect((payload['loan_payments'] as List).single['loan_id'], 'loan-1');

    await database.execute('DELETE FROM loan_payments');
    await database.execute('DELETE FROM loans');
    await database.execute('DELETE FROM budgets');
    await database.execute('DELETE FROM wallets');

    final backupFile = File(p.join(tempDirectory.path, 'backup.json'));
    await backupFile.writeAsString(jsonString, encoding: utf8);
    final result = await BackupService.restore(backupFile.path);

    expect(result.walletsAdded, 1);
    expect(result.monthlyBudgetsAdded, 1);
    expect(result.loansAdded, 1);
    expect(result.loanPaymentsAdded, 1);
    expect(result.errors, isEmpty);
    expect(
      (await database.get('SELECT is_archived FROM wallets'))['is_archived'],
      1,
    );
    expect(
      (await database.get('SELECT month FROM budgets'))['month'],
      '2026-07',
    );
    expect(
      (await database.get('SELECT loan_id FROM loan_payments'))['loan_id'],
      'loan-1',
    );
  });

  test('backup versions before v4 remain readable without new lists', () async {
    final backupFile = File(p.join(tempDirectory.path, 'backup-v3.json'));
    await backupFile.writeAsString(
      jsonEncode({
        'version': 3,
        'app': 'spendo',
        'categories': <Object>[],
        'transactions': <Object>[],
      }),
      encoding: utf8,
    );

    final result = await BackupService.previewRestore(backupFile.path);

    expect(result.errors, isEmpty);
    expect(result.monthlyBudgetsAdded, 0);
    expect(result.loansAdded, 0);
    expect(result.loanPaymentsAdded, 0);
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
    final fileName =
        Abi.current() == Abi.linuxArm64
            ? 'libpowersync_aarch64.so'
            : 'libpowersync_x64.so';
    return p.join(root, 'linux', fileName);
  }
  throw UnsupportedError(
    'PowerSync DB fixture chưa hỗ trợ ${Platform.operatingSystem}',
  );
}
