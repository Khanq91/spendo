import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqlite_async/sqlite3_common.dart';
import 'package:sqlite_async/sqlite_async.dart';
import 'package:spendo/core/db/schema.dart';
import 'package:spendo/features/transactions/data/transaction_repository.dart';
import 'package:spendo/features/wallets/data/wallet_repository.dart';

void main() {
  late Directory tempDirectory;
  late PowerSyncDatabase database;
  late WalletRepository walletRepository;
  late TransactionRepository transactionRepository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'spendo_wallet_test_',
    );
    database = PowerSyncDatabase.withFactory(
      _TestPowerSyncOpenFactory(
        path: p.join(tempDirectory.path, 'wallet.db'),
        libraryPath: _powerSyncLibraryPath(),
      ),
      schema: schema,
    );
    await database.initialize();
    walletRepository = WalletRepository(database: database);
    transactionRepository = TransactionRepository(database: database);
  });

  tearDown(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  test('wallet financial summary emits after a transaction changes', () async {
    await _insertWallet(database, id: 'wallet-1', initialBalance: 1000);
    final values = StreamIterator(
      walletRepository.watchFinancialSummary('wallet-1'),
    );

    expect(await values.moveNext(), isTrue);
    expect(values.current, (balance: 1000, x1: 1000, x2: 0));

    await _insertTransaction(
      database,
      id: 'expense-1',
      walletId: 'wallet-1',
      amount: 250,
      type: 'expense',
    );

    expect(await values.moveNext(), isTrue);
    expect(values.current, (balance: 750, x1: 1000, x2: 250));
    await values.cancel();
  });

  test('active financial summary aggregates wallets in one result', () async {
    await _insertWallet(database, id: 'wallet-1', initialBalance: 1000);
    await _insertWallet(database, id: 'wallet-2', initialBalance: 500);
    await _insertWallet(
      database,
      id: 'wallet-archived',
      initialBalance: 9000,
      isArchived: true,
    );
    await _insertTransaction(
      database,
      id: 'expense-1',
      walletId: 'wallet-2',
      amount: 200,
      type: 'expense',
    );
    final values = StreamIterator(
      walletRepository.watchActiveFinancialSummary(),
    );

    expect(await values.moveNext(), isTrue);
    expect(values.current, (balance: 1300, x1: 1500, x2: 200));

    await _insertTransaction(
      database,
      id: 'income-1',
      walletId: 'wallet-1',
      amount: 300,
      type: 'income',
    );

    expect(await values.moveNext(), isTrue);
    expect(values.current, (balance: 1600, x1: 1800, x2: 200));
    await values.cancel();
  });

  test(
    'wallet transaction stream emits after a transaction is added',
    () async {
      await _insertWallet(database, id: 'wallet-1', initialBalance: 0);
      final values = StreamIterator(
        transactionRepository.watchByWallet('wallet-1'),
      );

      expect(await values.moveNext(), isTrue);
      expect(values.current, isEmpty);

      await _insertTransaction(
        database,
        id: 'income-1',
        walletId: 'wallet-1',
        amount: 400,
        type: 'income',
      );

      expect(await values.moveNext(), isTrue);
      expect(values.current.map((transaction) => transaction.id), ['income-1']);
      await values.cancel();
    },
  );
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

Future<void> _insertWallet(
  PowerSyncDatabase database, {
  required String id,
  required int initialBalance,
  bool isArchived = false,
}) {
  return database.execute(
    '''INSERT INTO wallets(
         id, name, type, initial_balance, note, color_hex, sort_order, is_archived
       ) VALUES(?, ?, 'cash', ?, NULL, '#000000', 0, ?)''',
    [id, id, initialBalance.toString(), isArchived ? 1 : 0],
  );
}

Future<void> _insertTransaction(
  PowerSyncDatabase database, {
  required String id,
  required String walletId,
  required int amount,
  required String type,
}) {
  return database.execute(
    '''INSERT INTO transactions(
         id, amount, type, category_id, note, created_at, wallet_id, source
       ) VALUES(?, ?, ?, 'category-1', NULL, ?, ?, 'manual')''',
    [
      id,
      amount.toString(),
      type,
      DateTime.now().millisecondsSinceEpoch,
      walletId,
    ],
  );
}
