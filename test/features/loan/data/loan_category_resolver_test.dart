import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/db/schema.dart';
import 'package:spendo/features/loan/data/loan_category_resolver.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqlite_async/sqlite3_common.dart';
import 'package:sqlite_async/sqlite_async.dart';

void main() {
  late Directory tempDirectory;
  late PowerSyncDatabase database;
  late LoanCategoryResolver resolver;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDirectory = await Directory.systemTemp.createTemp('spendo_cat_test_');
    database = PowerSyncDatabase.withFactory(
      _TestPowerSyncOpenFactory(
        path: p.join(tempDirectory.path, 'cat.db'),
        libraryPath: _powerSyncLibraryPath(),
      ),
      schema: schema,
    );
    await database.initialize();
    resolver = LoanCategoryResolver(database: database);
  });

  tearDown(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  Future<List<Map<String, dynamic>>> categories() =>
      database.getAll('SELECT * FROM categories ORDER BY icon_name');

  test('the category is created the first time it is needed', () async {
    expect(await categories(), isEmpty);

    final id = await resolver.resolve(LoanCategoryKind.repay);

    final rows = await categories();
    expect(rows.single['id'], id);
    expect(rows.single['name'], 'Trả nợ');
    expect(rows.single['icon_name'], 'loan_repay');
    expect(rows.single['is_income'], 0);
    // Default categories cannot be deleted from the Danh mục screen, so a
    // loan transaction can never lose the category it points at.
    expect(rows.single['is_default'], 1);
  });

  test('asking again returns the same category, not a second one', () async {
    final first = await resolver.resolve(LoanCategoryKind.repay);
    final second = await resolver.resolve(LoanCategoryKind.repay);

    expect(second, first);
    expect((await categories()).length, 1);
  });

  test('the four kinds are four distinct categories', () async {
    for (final kind in LoanCategoryKind.values) {
      await resolver.resolve(kind);
    }

    final rows = await categories();
    expect(rows.length, 4);
    expect(rows.map((r) => r['icon_name']), [
      'loan_collect',
      'loan_in',
      'loan_out',
      'loan_repay',
    ]);
    // Money in and money out are separate names, so the two directions never
    // land in one bucket on the Thống kê screen.
    expect(
      rows.where((r) => r['is_income'] == 1).map((r) => r['name']),
      containsAll(['Thu nợ', 'Đi vay']),
    );
  });

  test('a restore that loses preferences adopts the categories it finds', () async {
    // The backup brought the category back under a new id while preferences
    // still point at the old one — the sequence that would otherwise mint a
    // duplicate "Trả nợ" on every restore.
    await database.execute(
      '''INSERT INTO categories(
           id, name, color_hex, icon_name, is_default, is_income, sort_order
         ) VALUES('restored', 'Trả nợ', '#B0BEC5', 'loan_repay', 1, 0, 7)''',
    );
    SharedPreferences.setMockInitialValues({'loan_cat_repay_id': 'stale-id'});

    final id = await resolver.resolve(LoanCategoryKind.repay);

    expect(id, 'restored');
    expect((await categories()).length, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('loan_cat_repay_id'), 'restored');
  });

  test('a user-made category with the same icon is not adopted', () async {
    // Only `is_default = 1` rows are ours; anything the user made themselves
    // is left alone even if the icon happens to match.
    await database.execute(
      '''INSERT INTO categories(
           id, name, color_hex, icon_name, is_default, is_income, sort_order
         ) VALUES('mine', 'Nợ của tôi', '#B0BEC5', 'loan_repay', 0, 0, 3)''',
    );

    final id = await resolver.resolve(LoanCategoryKind.repay);

    expect(id, isNot('mine'));
    expect((await categories()).length, 2);
  });

  test('a new category lands after the ones already on its side', () async {
    await database.execute(
      '''INSERT INTO categories(
           id, name, color_hex, icon_name, is_default, is_income, sort_order
         ) VALUES('food', 'Ăn uống', '#FF6B6B', 'restaurant', 1, 0, 4)''',
    );

    await resolver.resolve(LoanCategoryKind.repay);

    final row = await database.get(
      "SELECT sort_order FROM categories WHERE icon_name = 'loan_repay'",
    );
    expect(row['sort_order'], 5);
  });

  test('payments and principal map to opposite sides of the ledger', () {
    expect(
      LoanCategoryKind.paymentFor(LoanType.borrowed),
      LoanCategoryKind.repay,
    );
    expect(
      LoanCategoryKind.paymentFor(LoanType.lent),
      LoanCategoryKind.collect,
    );
    expect(
      LoanCategoryKind.fundingFor(LoanType.borrowed),
      LoanCategoryKind.borrowIn,
    );
    expect(
      LoanCategoryKind.fundingFor(LoanType.lent),
      LoanCategoryKind.lendOut,
    );
    // Paying back a loan is money out; the principal arriving is money in.
    expect(LoanCategoryKind.repay.isIncome, isFalse);
    expect(LoanCategoryKind.borrowIn.isIncome, isTrue);
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
