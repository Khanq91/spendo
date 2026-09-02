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

  test('backup v5 round-trip preserves local financial data', () async {
    await database.execute('''INSERT INTO categories(
      id, name, color_hex, icon_name, is_default, is_income, sort_order
    ) VALUES(
      'default-food', 'Ăn uống', '#FF6B6B', 'restaurant', 1, 0, 0
    )''');
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
           note, color_hex, is_closed, repayment_mode
         ) VALUES(
           'loan-1', 'Khoản vay', 'borrowed', '1000000', 'An',
           '2026-07-01T00:00:00.000', NULL, NULL, '#123456', 0, 'installment'
         )''');
    await database.execute('''INSERT INTO loans(
           id, title, type, principal, contact_name, start_date, due_date,
           note, color_hex, is_closed, repayment_mode, is_tracking_only
         ) VALUES(
           'loan-2', 'Nợ theo dõi', 'lent', '400000', 'Bình',
           '2026-07-02T00:00:00.000', NULL, NULL, '#654321', 0, NULL, 1
         )''');
    await database.execute(
      '''INSERT INTO loan_installments(id, loan_id, seq, amount, due_date)
         VALUES('inst-1', 'loan-1', 1, '400000', '2026-08-01T00:00:00.000')''',
    );
    await database.execute(
      '''INSERT INTO loan_payments(id, loan_id, amount, paid_at, note)
         VALUES(
           'payment-1', 'loan-1', '250000',
           '2026-07-10T00:00:00.000', 'Đợt 1'
         )''',
    );

    final jsonString = await BackupService.exportBackupAsString();
    final payload = jsonDecode(jsonString) as Map<String, dynamic>;

    expect(payload['version'], 5);
    expect((payload['wallets'] as List).single['is_archived'], isTrue);
    expect((payload['categories'] as List).single['is_default'], isTrue);
    expect((payload['budgets'] as List).single['month'], '2026-07');
    expect((payload['loan_payments'] as List).single['loan_id'], 'loan-1');
    final exportedLoans = (payload['loans'] as List)
        .cast<Map<String, dynamic>>();
    expect(
      exportedLoans.firstWhere((l) => l['id'] == 'loan-1')['repayment_mode'],
      'installment',
    );
    // Which sổ a loan is in survives the round trip; without it a restore
    // would quietly move every tracking loan into the spending book.
    expect(
      exportedLoans.firstWhere((l) => l['id'] == 'loan-1')['is_tracking_only'],
      isFalse,
    );
    expect(
      exportedLoans.firstWhere((l) => l['id'] == 'loan-2')['is_tracking_only'],
      isTrue,
    );
    expect((payload['loan_installments'] as List).single['seq'], 1);

    await database.execute('DELETE FROM loan_installments');
    await database.execute('DELETE FROM loan_payments');
    await database.execute('DELETE FROM loans');
    await database.execute('DELETE FROM budgets');
    await database.execute('DELETE FROM wallets');
    await database.execute('DELETE FROM categories');

    final backupFile = File(p.join(tempDirectory.path, 'backup.json'));
    await backupFile.writeAsString(jsonString, encoding: utf8);
    final result = await BackupService.restore(backupFile.path);

    expect(result.walletsAdded, 1);
    expect(result.monthlyBudgetsAdded, 1);
    expect(result.loansAdded, 2);
    expect(result.loanPaymentsAdded, 1);
    expect(result.loanInstallmentsAdded, 1);
    expect(result.errors, isEmpty);
    expect(
      (await database.get(
        "SELECT is_tracking_only FROM loans WHERE id = 'loan-2'",
      ))['is_tracking_only'],
      1,
    );
    expect(
      (await database.get(
        "SELECT is_tracking_only FROM loans WHERE id = 'loan-1'",
      ))['is_tracking_only'],
      0,
    );
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
    expect(
      (await database.get('SELECT is_default FROM categories'))['is_default'],
      1,
    );
    expect(
      (await database.get(
        'SELECT amount, seq FROM loan_installments',
      ))['amount'],
      '400000',
    );
    expect(
      (await database.get(
        "SELECT repayment_mode FROM loans WHERE id = 'loan-1'",
      ))['repayment_mode'],
      'installment',
    );
  });

  test('a backup written before schedules restores as a free loan', () async {
    await database.execute('DELETE FROM loan_installments');
    await database.execute('DELETE FROM loan_payments');
    await database.execute('DELETE FROM loans');

    // v4 knew nothing of repayment_mode, funding_transaction_id or
    // loan_installments; those loans have to come back as free repayment
    // rather than being rejected for the fields they cannot have.
    final backupFile = File(p.join(tempDirectory.path, 'backup-v4-loan.json'));
    await backupFile.writeAsString(
      jsonEncode({
        'version': 4,
        'app': 'spendo',
        'categories': <Object>[],
        'transactions': <Object>[],
        'loans': [
          {
            'id': 'loan-old',
            'title': 'Vay cũ',
            'type': 'borrowed',
            'principal': 2000000,
            'contact_name': 'Bình',
            'start_date': '2026-01-01T00:00:00.000',
            'due_date': null,
            'note': null,
            'color_hex': '#123456',
            'is_closed': false,
          },
        ],
        'loan_payments': [
          {
            'id': 'payment-old',
            'loan_id': 'loan-old',
            'amount': 500000,
            'paid_at': '2026-02-01T00:00:00.000',
            'note': null,
          },
        ],
      }),
      encoding: utf8,
    );

    final result = await BackupService.restore(backupFile.path);

    expect(result.errors, isEmpty);
    expect(result.loansAdded, 1);
    expect(result.loanPaymentsAdded, 1);
    expect(result.loanInstallmentsAdded, 0);
    expect(
      (await database.get(
        "SELECT repayment_mode FROM loans WHERE id = 'loan-old'",
      ))['repayment_mode'],
      isNull,
    );
    // No flag in the file either — a loan from before the tracking sổ existed
    // belongs to the spending one, which is where 0 puts it.
    expect(
      (await database.get(
        "SELECT is_tracking_only FROM loans WHERE id = 'loan-old'",
      ))['is_tracking_only'],
      0,
    );
    expect(
      (await database.get(
        "SELECT transaction_id FROM loan_payments WHERE id = 'payment-old'",
      ))['transaction_id'],
      isNull,
    );

    await database.execute('DELETE FROM loan_payments');
    await database.execute('DELETE FROM loans');
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
    expect(result.loanInstallmentsAdded, 0);
  });

  test('restore repairs duplicate category references before returning', () async {
    final backupFile = File(
      p.join(tempDirectory.path, 'backup-duplicate-category.json'),
    );
    await backupFile.writeAsString(
      jsonEncode({
        'version': 4,
        'app': 'spendo',
        'categories': [
          {
            'id': 'custom-food',
            'name': 'Ăn uống',
            'color_hex': '#000000',
            'icon_name': 'more_horiz',
            'is_default': false,
            'is_income': false,
            'sort_order': 1,
          },
        ],
        'transactions': [
          {
            'id': 'transaction-from-duplicate-category',
            'amount': 1000,
            'type': 'expense',
            'category_id': 'custom-food',
            'note': null,
            'created_at': 1,
            'wallet_id': null,
            'source': 'manual',
          },
        ],
      }),
      encoding: utf8,
    );

    await BackupService.restore(backupFile.path);

    expect(
      await database.getAll(
        "SELECT id FROM categories WHERE name = 'Ăn uống' AND is_income = 0",
      ),
      hasLength(1),
    );
    expect(
      (await database.get(
        "SELECT category_id FROM transactions WHERE id = 'transaction-from-duplicate-category'",
      ))['category_id'],
      'default-food',
    );
  });

  test('malformed payload is rejected before any row is written', () async {
    final backupFile = File(
      p.join(tempDirectory.path, 'backup-malformed.json'),
    );
    await backupFile.writeAsString(
      jsonEncode({
        'version': 4,
        'app': 'spendo',
        'wallets': [
          {
            'id': 'wallet-before-invalid-row',
            'name': 'Ví không được ghi',
            'type': 'cash',
            'initial_balance': 0,
            'note': null,
            'color_hex': '#000000',
            'sort_order': 0,
            'is_archived': false,
          },
        ],
        'categories': [
          {
            'id': 'invalid-category',
            'name': 123,
            'color_hex': '#000000',
            'icon_name': 'more_horiz',
            'is_income': false,
            'sort_order': 0,
          },
        ],
        'transactions': <Object>[],
      }),
      encoding: utf8,
    );

    final result = await BackupService.restore(backupFile.path);

    expect(result.errors, isNotEmpty);
    expect(
      await database.getOptional('SELECT id FROM wallets WHERE id = ?', [
        'wallet-before-invalid-row',
      ]),
      isNull,
    );
  });

  test('database failure rolls back rows written earlier in restore', () async {
    const triggerName = 'fail_stab_004_category_restore';
    await database.execute('''
      CREATE TRIGGER $triggerName
      INSTEAD OF INSERT ON categories
      WHEN NEW.id = 'category-that-fails'
      BEGIN
        SELECT RAISE(ABORT, 'forced restore failure');
      END
    ''');

    final backupFile = File(
      p.join(tempDirectory.path, 'backup-db-failure.json'),
    );
    await backupFile.writeAsString(
      jsonEncode({
        'version': 4,
        'app': 'spendo',
        'wallets': [
          {
            'id': 'wallet-before-db-failure',
            'name': 'Ví phải rollback',
            'type': 'cash',
            'initial_balance': 0,
            'note': null,
            'color_hex': '#000000',
            'sort_order': 0,
            'is_archived': false,
          },
        ],
        'categories': [
          {
            'id': 'category-that-fails',
            'name': 'Danh mục gây lỗi',
            'color_hex': '#000000',
            'icon_name': 'more_horiz',
            'is_income': false,
            'sort_order': 0,
          },
        ],
        'transactions': <Object>[],
      }),
      encoding: utf8,
    );

    try {
      await expectLater(
        BackupService.restore(backupFile.path),
        throwsA(anything),
      );
      expect(
        await database.getOptional('SELECT id FROM wallets WHERE id = ?', [
          'wallet-before-db-failure',
        ]),
        isNull,
      );
    } finally {
      await database.execute('DROP TRIGGER IF EXISTS $triggerName');
    }
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
