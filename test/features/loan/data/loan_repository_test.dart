import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';
import 'package:spendo/core/db/schema.dart';
import 'package:spendo/features/loan/data/loan_repository.dart';
import 'package:spendo/features/loan/domain/loan.dart';
import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqlite_async/sqlite3_common.dart';
import 'package:sqlite_async/sqlite_async.dart';

void main() {
  late Directory tempDirectory;
  late PowerSyncDatabase database;
  late LoanRepository repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('spendo_loan_test_');
    database = PowerSyncDatabase.withFactory(
      _TestPowerSyncOpenFactory(
        path: p.join(tempDirectory.path, 'loan.db'),
        libraryPath: _powerSyncLibraryPath(),
      ),
      schema: schema,
    );
    await database.initialize();
    repository = LoanRepository(database: database);
  });

  tearDown(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  Future<String> addLoan({
    RepaymentMode mode = RepaymentMode.free,
    int principal = 9000000,
  }) => repository.add(
    Loan(
      id: '',
      title: 'Vay mua xe',
      type: LoanType.borrowed,
      principal: principal,
      contactName: 'Anh A',
      startDate: DateTime(2026, 9),
      colorHex: '#B23A2E',
      isClosed: false,
      repaymentMode: mode,
    ),
  );

  List<LoanInstallment> schedule(String loanId, List<int> amounts) => [
    for (var i = 0; i < amounts.length; i++)
      LoanInstallment(
        id: 'gen_${i + 1}',
        loanId: loanId,
        seq: i + 1,
        amount: amounts[i],
        dueDate: DateTime(2026, 10 + i, 15),
      ),
  ];

  test('a new loan comes back with the id it was given', () async {
    final id = await addLoan();

    expect(id, isNotEmpty);
    final loans = await repository.getAll();
    expect(loans.single.id, id);
    expect(loans.single.repaymentMode, RepaymentMode.free);
  });

  test('replaceInstallments writes the schedule and flips the mode', () async {
    final id = await addLoan();

    await repository.replaceInstallments(
      id,
      schedule(id, [3000000, 3000000, 3000000]),
    );

    final saved = await repository.getInstallments(id);
    expect(saved.map((i) => i.seq), [1, 2, 3]);
    expect(saved.map((i) => i.amount), [3000000, 3000000, 3000000]);
    expect(saved.first.dueDate, DateTime(2026, 10, 15));
    expect(
      (await repository.getAll()).single.repaymentMode,
      RepaymentMode.installment,
    );
  });

  test('replacing a schedule leaves no rows from the old one', () async {
    final id = await addLoan();
    await repository.replaceInstallments(
      id,
      schedule(id, [3000000, 3000000, 3000000]),
    );

    await repository.replaceInstallments(id, schedule(id, [4500000, 4500000]));

    final saved = await repository.getInstallments(id);
    expect(saved.length, 2);
    // Seq is assigned on write, so a shorter schedule cannot leave a stale
    // "Đợt 3" behind.
    expect(saved.map((i) => i.seq), [1, 2]);
  });

  test('a hand-edited list is renumbered from 1 on save', () async {
    final id = await addLoan();

    await repository.replaceInstallments(id, [
      LoanInstallment(
        id: 'x',
        loanId: id,
        seq: 7,
        amount: 1000000,
        dueDate: DateTime(2026, 10, 15),
      ),
      LoanInstallment(
        id: 'y',
        loanId: id,
        seq: 9,
        amount: 2000000,
        dueDate: DateTime(2026, 11, 15),
      ),
    ]);

    expect((await repository.getInstallments(id)).map((i) => i.seq), [1, 2]);
  });

  test('the due date is stored as a plain date', () async {
    final id = await addLoan();

    await repository.replaceInstallments(id, [
      LoanInstallment(
        id: 'x',
        loanId: id,
        seq: 1,
        amount: 1000000,
        dueDate: DateTime(2026, 10, 15, 23, 45),
      ),
    ]);

    expect(
      (await repository.getInstallments(id)).single.dueDate,
      DateTime(2026, 10, 15),
    );
  });

  test('clearing the schedule returns the loan to free repayment', () async {
    final id = await addLoan();
    await repository.replaceInstallments(id, schedule(id, [4500000, 4500000]));
    await repository.addPayment(
      loanId: id,
      amount: 1000000,
      paidAt: DateTime(2026, 10, 16),
    );

    await repository.clearInstallments(id);

    expect(await repository.getInstallments(id), isEmpty);
    expect(
      (await repository.getAll()).single.repaymentMode,
      RepaymentMode.free,
    );
    // Payments are what actually happened; dropping the plan must not touch
    // them, nor what is still owed.
    expect(await repository.getTotalPaid(id), 1000000);
  });

  test('watchInstallments emits again when the schedule changes', () async {
    final id = await addLoan();
    final values = StreamIterator(repository.watchInstallments(id));

    expect(await values.moveNext(), isTrue);
    expect(values.current, isEmpty);

    await repository.replaceInstallments(id, schedule(id, [4500000, 4500000]));

    expect(await values.moveNext(), isTrue);
    expect(values.current.length, 2);
    await values.cancel();
  });

  test('deleting a loan takes its schedule with it', () async {
    final id = await addLoan();
    await repository.replaceInstallments(id, schedule(id, [4500000, 4500000]));
    await repository.addPayment(
      loanId: id,
      amount: 1000000,
      paidAt: DateTime(2026, 10, 16),
    );

    await repository.delete(id);

    expect(await repository.getAllInstallments(), isEmpty);
    expect(await repository.getAllPayments(), isEmpty);
    expect(await repository.getAll(), isEmpty);
  });

  test('watchInstallmentsByLoan keys every schedule by its loan', () async {
    final first = await addLoan();
    final second = await addLoan(principal: 4000000);
    await repository.replaceInstallments(
      first,
      schedule(first, [3000000, 3000000, 3000000]),
    );
    await repository.replaceInstallments(
      second,
      schedule(second, [2000000, 2000000]),
    );

    final grouped = await repository.watchInstallmentsByLoan().first;

    expect(grouped[first]?.length, 3);
    expect(grouped[second]?.length, 2);
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
