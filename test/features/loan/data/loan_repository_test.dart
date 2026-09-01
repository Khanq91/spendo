import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    SharedPreferences.setMockInitialValues({});
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
    LoanType type = LoanType.borrowed,
    String? fundingWalletId,
  }) => repository.add(
    Loan(
      id: '',
      title: 'Vay mua xe',
      type: type,
      principal: principal,
      contactName: 'Anh A',
      startDate: DateTime(2026, 9),
      colorHex: '#B23A2E',
      isClosed: false,
      repaymentMode: mode,
    ),
    fundingWalletId: fundingWalletId,
  );

  Future<List<Map<String, dynamic>>> transactions() =>
      database.getAll('SELECT * FROM transactions');

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

  // ── Wallet linkage (GĐ2) ──────────────────────────────────────────────────

  test('a payment writes the transaction that moves the money', () async {
    final id = await addLoan();

    await repository.addPayment(
      loanId: id,
      amount: 2000000,
      paidAt: DateTime(2026, 10, 16),
      loanType: LoanType.borrowed,
      walletId: 'wallet-1',
      title: 'Vay mua xe',
    );

    final rows = await transactions();
    expect(rows.single['amount'], '2000000');
    // Repaying a loan you took is an expense, and it lands in the wallet.
    expect(rows.single['type'], 'expense');
    expect(rows.single['wallet_id'], 'wallet-1');
    expect(rows.single['source'], 'loan');
    expect(rows.single['note'], 'Trả nợ: Vay mua xe');

    final payment = (await repository.getAllPayments()).single;
    expect(payment.transactionId, rows.single['id']);
  });

  test('collecting on a loan you gave is income, not expense', () async {
    final id = await addLoan(type: LoanType.lent);

    await repository.addPayment(
      loanId: id,
      amount: 1000000,
      paidAt: DateTime(2026, 10, 16),
      loanType: LoanType.lent,
      walletId: 'wallet-1',
      title: 'Cho B mượn',
    );

    expect((await transactions()).single['type'], 'income');
  });

  test('a payment note of its own beats the generated one', () async {
    final id = await addLoan();

    await repository.addPayment(
      loanId: id,
      amount: 1000000,
      paidAt: DateTime(2026, 10, 16),
      note: 'Chuyển khoản MB',
      loanType: LoanType.borrowed,
      title: 'Vay mua xe',
    );

    expect((await transactions()).single['note'], 'Chuyển khoản MB');
  });

  test('a payment with no wallet still writes the transaction', () async {
    final id = await addLoan();

    await repository.addPayment(
      loanId: id,
      amount: 1000000,
      paidAt: DateTime(2026, 10, 16),
      loanType: LoanType.borrowed,
      title: 'Vay mua xe',
    );

    // Wallet is optional everywhere in the app; the entry still belongs in the
    // statistics.
    expect((await transactions()).single['wallet_id'], isNull);
  });

  test('the same category serves every payment, made once', () async {
    final id = await addLoan();

    for (var i = 0; i < 3; i++) {
      await repository.addPayment(
        loanId: id,
        amount: 1000000,
        paidAt: DateTime(2026, 10, 16 + i),
        loanType: LoanType.borrowed,
        title: 'Vay mua xe',
      );
    }

    final categories = await database.getAll(
      "SELECT id FROM categories WHERE icon_name = 'loan_repay'",
    );
    expect(categories.length, 1);
    final rows = await transactions();
    expect(rows.length, 3);
    expect(rows.map((r) => r['category_id']).toSet().length, 1);
  });

  test('deleting a payment takes its transaction with it', () async {
    final id = await addLoan();
    await repository.addPayment(
      loanId: id,
      amount: 2000000,
      paidAt: DateTime(2026, 10, 16),
      loanType: LoanType.borrowed,
      walletId: 'wallet-1',
      title: 'Vay mua xe',
    );

    await repository.deletePayment((await repository.getAllPayments()).single.id);

    expect(await transactions(), isEmpty);
    expect(await repository.getAllPayments(), isEmpty);
  });

  test('an undo puts back the transaction that was deleted, id and all', () async {
    final id = await addLoan();
    await repository.addPayment(
      loanId: id,
      amount: 2000000,
      paidAt: DateTime(2026, 10, 16),
      loanType: LoanType.borrowed,
      walletId: 'wallet-1',
      title: 'Vay mua xe',
    );
    final payment = (await repository.getAllPayments()).single;
    final transactionId = payment.transactionId!;
    await repository.deletePayment(payment.id);

    await repository.addPayment(
      loanId: id,
      amount: payment.amount,
      paidAt: payment.paidAt,
      note: payment.note,
      loanType: LoanType.borrowed,
      walletId: 'wallet-1',
      title: 'Vay mua xe',
      transactionId: transactionId,
    );

    final rows = await transactions();
    expect(rows.single['id'], transactionId);
    expect(rows.single['wallet_id'], 'wallet-1');
  });

  test('a payment recorded without a transaction stays without one', () async {
    final id = await addLoan();

    // The path an undo takes for a payment made before wallets were linked.
    await repository.addPayment(
      loanId: id,
      amount: 1000000,
      paidAt: DateTime(2026, 10, 16),
      withTransaction: false,
    );

    expect(await transactions(), isEmpty);
    expect((await repository.getAllPayments()).single.transactionId, isNull);
  });

  test('booking the principal credits the wallet and links back', () async {
    final id = await addLoan(fundingWalletId: 'wallet-1');

    final rows = await transactions();
    expect(rows.single['amount'], '9000000');
    // Money borrowed arrives, so it is income against the wallet.
    expect(rows.single['type'], 'income');
    expect(rows.single['wallet_id'], 'wallet-1');
    expect(rows.single['source'], 'loan');

    final loan = (await repository.getAll()).single;
    expect(loan.id, id);
    expect(loan.fundingTransactionId, rows.single['id']);
  });

  test('lending money out debits the wallet instead', () async {
    await addLoan(type: LoanType.lent, fundingWalletId: 'wallet-1');

    expect((await transactions()).single['type'], 'expense');
  });

  test('a loan with the toggle off writes no transaction', () async {
    await addLoan();

    expect(await transactions(), isEmpty);
    expect((await repository.getAll()).single.fundingTransactionId, isNull);
  });

  test('deleting a loan sweeps up every transaction it wrote', () async {
    final id = await addLoan(fundingWalletId: 'wallet-1');
    await repository.addPayment(
      loanId: id,
      amount: 2000000,
      paidAt: DateTime(2026, 10, 16),
      loanType: LoanType.borrowed,
      walletId: 'wallet-1',
      title: 'Vay mua xe',
    );
    await repository.addPayment(
      loanId: id,
      amount: 1000000,
      paidAt: DateTime(2026, 11, 16),
      loanType: LoanType.borrowed,
      walletId: 'wallet-1',
      title: 'Vay mua xe',
    );
    expect((await transactions()).length, 3);

    await repository.delete(id);

    // Nothing is left pointing at a loan that no longer exists.
    expect(await transactions(), isEmpty);
  });

  test('deleting a loan leaves other loans transactions alone', () async {
    final first = await addLoan(fundingWalletId: 'wallet-1');
    final second = await addLoan(fundingWalletId: 'wallet-2');
    await repository.addPayment(
      loanId: second,
      amount: 1000000,
      paidAt: DateTime(2026, 10, 16),
      loanType: LoanType.borrowed,
      title: 'Vay mua xe',
    );

    await repository.delete(first);

    final rows = await transactions();
    expect(rows.length, 2);
    expect(rows.every((r) => r['wallet_id'] != 'wallet-1'), isTrue);
  });

  test('findByTransaction reaches the loan from either kind of link', () async {
    final id = await addLoan(fundingWalletId: 'wallet-1');
    await repository.addPayment(
      loanId: id,
      amount: 1000000,
      paidAt: DateTime(2026, 10, 16),
      loanType: LoanType.borrowed,
      title: 'Vay mua xe',
    );
    final loan = (await repository.getAll()).single;
    final paymentTxId = (await repository.getAllPayments()).single.transactionId;

    expect(
      (await repository.findByTransaction(loan.fundingTransactionId!))?.id,
      id,
    );
    expect((await repository.findByTransaction(paymentTxId!))?.id, id);
    expect(await repository.findByTransaction('not-ours'), isNull);
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
