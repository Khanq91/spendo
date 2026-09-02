import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/budget/data/budget_repository.dart';
import '../../features/budget/data/category_budget_repository.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/loan/data/loan_repository.dart';
import '../../features/reminders/data/reminder_repository.dart';
import '../../features/transactions/data/transaction_repository.dart';
import '../../features/wallets/data/wallet_repository.dart';
import '../db/powersync_db.dart';

// ── Result types ──────────────────────────────────────────────────────────────

class BackupResult {
  final int categories;
  final int transactions;
  final int reminders;
  final int categoryBudgets;
  final int monthlyBudgets;
  final int wallets;
  final int loans;
  final int loanPayments;
  final int loanInstallments;
  final List<String> errors;

  const BackupResult({
    required this.categories,
    required this.transactions,
    this.reminders = 0,
    this.categoryBudgets = 0,
    this.monthlyBudgets = 0,
    this.wallets = 0,
    this.loans = 0,
    this.loanPayments = 0,
    this.loanInstallments = 0,
    this.errors = const [],
  });
}

class RestoreResult {
  final int categoriesAdded;
  final int transactionsAdded;
  final int categoriesSkipped;
  final int transactionsSkipped;
  final int remindersAdded;
  final int remindersSkipped;
  final int budgetsAdded;
  final int budgetsSkipped;
  final int walletsAdded;
  final int walletsSkipped;
  final int monthlyBudgetsAdded;
  final int monthlyBudgetsSkipped;
  final int loansAdded;
  final int loansSkipped;
  final int loanPaymentsAdded;
  final int loanPaymentsSkipped;
  final int loanInstallmentsAdded;
  final int loanInstallmentsSkipped;
  final List<String> errors;

  const RestoreResult({
    required this.categoriesAdded,
    required this.transactionsAdded,
    required this.categoriesSkipped,
    required this.transactionsSkipped,
    this.remindersAdded = 0,
    this.remindersSkipped = 0,
    this.budgetsAdded = 0,
    this.budgetsSkipped = 0,
    this.walletsAdded = 0,
    this.walletsSkipped = 0,
    this.monthlyBudgetsAdded = 0,
    this.monthlyBudgetsSkipped = 0,
    this.loansAdded = 0,
    this.loansSkipped = 0,
    this.loanPaymentsAdded = 0,
    this.loanPaymentsSkipped = 0,
    this.loanInstallmentsAdded = 0,
    this.loanInstallmentsSkipped = 0,
    this.errors = const [],
  });
}

// ── Version ───────────────────────────────────────────────────────────────────

const _kBackupVersion = 5;
const _kBackupAppTag = 'spendo';

typedef _SqlExecutor = Future<void> Function(
  String sql,
  List<Object?> parameters,
);
typedef _RowReader = Future<Iterable<Map<String, Object?>>> Function(String sql);

class BackupService {
  // ── Export ──────────────────────────────────────────────────────────────────

  static Future<BackupResult> exportBackup() async {
    final jsonString = await exportBackupAsString();

    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName =
        'spendo_backup_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonString, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Spendo — Backup dữ liệu',
    );

    final catRepo = CategoryRepository();
    final txRepo = TransactionRepository();
    final reminderRepo = ReminderRepository();
    final budgetRepo = CategoryBudgetRepository();
    final monthlyBudgetRepo = BudgetRepository();
    final walletRepo = WalletRepository();
    final loanRepo = LoanRepository();

    return BackupResult(
      categories: (await catRepo.getAll()).length,
      transactions: (await txRepo.getAll()).length,
      reminders: (await reminderRepo.getAll()).length,
      categoryBudgets: (await budgetRepo.getAll()).length,
      monthlyBudgets: (await monthlyBudgetRepo.getAll()).length,
      wallets: (await walletRepo.getAllIncludingArchived()).length,
      loans: (await loanRepo.getAll()).length,
      loanPayments: (await loanRepo.getAllPayments()).length,
      loanInstallments: (await loanRepo.getAllInstallments()).length,
    );
  }

  static Future<String> exportBackupAsString() async {
    final catRepo = CategoryRepository();
    final txRepo = TransactionRepository();
    final reminderRepo = ReminderRepository();
    final budgetRepo = CategoryBudgetRepository();
    final monthlyBudgetRepo = BudgetRepository();
    final walletRepo = WalletRepository();
    final loanRepo = LoanRepository();

    final loans = await loanRepo.getAll();
    final loanPayments = await loanRepo.getAllPayments();
    final loanInstallments = await loanRepo.getAllInstallments();
    final categories = await catRepo.getAll();
    final transactions = await txRepo.getAll();
    final reminders = await reminderRepo.getAll();
    final budgets = await budgetRepo.getAll();
    final monthlyBudgets = await monthlyBudgetRepo.getAll();
    final wallets = await walletRepo.getAllIncludingArchived();

    final payload = {
      'version': _kBackupVersion,
      'app': _kBackupAppTag,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'wallets': wallets
          .map((w) => {
                'id': w.id,
                'name': w.name,
                'type': w.type.name,
                'initial_balance': w.initialBalance,
                'note': w.note,
                'color_hex': w.colorHex,
                'sort_order': w.sortOrder,
                'is_archived': w.isArchived,
              })
          .toList(),
      'categories': categories
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'color_hex': c.colorHex,
                'icon_name': c.iconName,
                'is_default': c.isDefault,
                'is_income': c.isIncome,
                'sort_order': c.sortOrder,
              })
          .toList(),
      'transactions': transactions
          .map((t) => {
                'id': t.id,
                'amount': t.amount,
                'type': t.type,
                'category_id': t.categoryId,
                'note': t.note,
                'created_at': t.createdAt.millisecondsSinceEpoch,
                'wallet_id': t.walletId,
                'source': t.source,
              })
          .toList(),
      'recurring_reminders': reminders
          .map((r) => {
                'id': r.id,
                'title': r.title,
                'category_id': r.categoryId,
                'amount_hint': r.amountHint,
                'frequency': r.frequency.name,
                'day_of_week': r.dayOfWeek,
                'day_of_month': r.dayOfMonth,
                'hour': r.hour,
                'minute': r.minute,
                'is_active': r.isActive,
                'next_trigger': r.nextTrigger.toIso8601String(),
                'warn_before_hours': r.warnBeforeHours,
              })
          .toList(),
      'category_budgets': budgets
          .map((b) => {
                'id': b.id,
                'category_id': b.categoryId,
                'amount': b.amount,
              })
          .toList(),
      'budgets': monthlyBudgets
          .map((b) => {
                'id': b.id,
                'amount': b.amount,
                'month': b.month,
              })
          .toList(),
      'loans': loans
          .map((l) => {
            'id': l.id,
            'title': l.title,
            'type': l.type.name,
            'principal': l.principal,
            'contact_name': l.contactName,
            'start_date': l.startDate.toIso8601String(),
            'due_date': l.dueDate?.toIso8601String(),
            'note': l.note,
            'color_hex': l.colorHex,
            'is_closed': l.isClosed,
            'repayment_mode': l.repaymentMode.name,
            'funding_transaction_id': l.fundingTransactionId,
            'is_tracking_only': l.isTrackingOnly,
          }).toList(),
      'loan_payments': loanPayments
          .map((p) => {
                'id': p.id,
                'loan_id': p.loanId,
                'amount': p.amount,
                'paid_at': p.paidAt.toIso8601String(),
                'note': p.note,
                'transaction_id': p.transactionId,
              })
          .toList(),
      'loan_installments': loanInstallments
          .map((i) => {
                'id': i.id,
                'loan_id': i.loanId,
                'seq': i.seq,
                'amount': i.amount,
                'due_date': i.dueDate.toIso8601String(),
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  // ── Preview & Restore ────────────────────────────────────────────────────────

  static Future<RestoreResult> previewRestore(String filePath) async {
    return _processRestore(filePath, dryRun: true);
  }

  static Future<RestoreResult> restore(String filePath) async {
    return _processRestore(filePath, dryRun: false);
  }

  static Future<RestoreResult> _processRestore(
    String filePath, {
    required bool dryRun,
    _SqlExecutor? execute,
    _RowReader? readRows,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const RestoreResult(
        categoriesAdded: 0,
        transactionsAdded: 0,
        categoriesSkipped: 0,
        transactionsSkipped: 0,
        errors: ['File không tồn tại'],
      );
    }

    final Map<String, dynamic> data;
    try {
      final content = await file.readAsString(encoding: utf8);
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return const RestoreResult(
        categoriesAdded: 0,
        transactionsAdded: 0,
        categoriesSkipped: 0,
        transactionsSkipped: 0,
        errors: ['File không hợp lệ — không parse được JSON'],
      );
    }

    final _RestorePayload payload;
    try {
      payload = _RestorePayload.fromJson(data);
    } on FormatException catch (error) {
      return RestoreResult(
        categoriesAdded: 0,
        transactionsAdded: 0,
        categoriesSkipped: 0,
        transactionsSkipped: 0,
        errors: [error.message],
      );
    }

    if (!dryRun && execute == null) {
      return db.writeTransaction((transaction) async {
        final result = await _processRestore(
          filePath,
          dryRun: false,
          execute: (sql, parameters) async {
            await transaction.execute(sql, parameters);
          },
          readRows: transaction.getAll,
        );
        await repairDuplicateCategoriesInTransaction(
          readRows: (sql, parameters) => transaction.getAll(sql, parameters),
          execute: (sql, parameters) => transaction.execute(sql, parameters),
        );
        return result;
      });
    }

    final rawWallets = payload.wallets;
    final rawCats = payload.categories;
    final rawLoans = payload.loans;
    final rawLoanPayments = payload.loanPayments;
    final rawLoanInstallments = payload.loanInstallments;
    final rawTxs = payload.transactions;
    final rawReminders = payload.reminders;
    final rawBudgets = payload.categoryBudgets;
    final rawMonthlyBudgets = payload.monthlyBudgets;

    final existingCatIds = await _getExistingCategoryIds(readRows);
    final existingTxIds = await _getExistingTransactionIds(readRows);
    final existingReminderIds = await _getExistingReminderIds(readRows);
    final existingBudgetCatIds = await _getExistingBudgetCategoryIds(readRows);
    final existingWalletIds = await _getExistingWalletIds(readRows);
    final existingLoanIds = await _getExistingLoanIds(readRows);
    final existingLoanPaymentIds = await _getExistingLoanPaymentIds(readRows);
    final existingLoanInstallmentIds = await _getExistingLoanInstallmentIds(
      readRows,
    );
    final existingMonthlyBudgetIds = await _getExistingMonthlyBudgetIds(readRows);
    final existingMonthlyBudgetMonths = await _getExistingMonthlyBudgetMonths(readRows);

    int catsAdded = 0, catsSkipped = 0;
    int txsAdded = 0, txsSkipped = 0;
    int remindersAdded = 0, remindersSkipped = 0;
    int budgetsAdded = 0, budgetsSkipped = 0;
    int walletsAdded = 0, walletsSkipped = 0;
    int loansAdded = 0, loansSkipped = 0;
    int loanPaymentsAdded = 0, loanPaymentsSkipped = 0;
    int loanInstallmentsAdded = 0, loanInstallmentsSkipped = 0;
    int monthlyBudgetsAdded = 0, monthlyBudgetsSkipped = 0;
    final errors = <String>[];

    for (final l in rawLoans) {
      final id = l['id'] as String?;
      if (id == null || id.isEmpty) {
        errors.add('Khoản vay thiếu id: ${l['title']}');
        continue;
      }
      if (existingLoanIds.contains(id)) {
        loansSkipped++;
        continue;
      }
      loansAdded++;
      if (!dryRun) {
        await _insertLoan(l, execute!);
        existingLoanIds.add(id);
      }
    }

    final backupLoanIds = rawLoans
        .map((loan) => loan['id'])
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    final validLoanIds = {...existingLoanIds, ...backupLoanIds};
    for (final payment in rawLoanPayments) {
      final id = payment['id'] as String?;
      final loanId = payment['loan_id'] as String?;
      if (id == null || id.isEmpty) {
        errors.add('Lần trả nợ thiếu id');
        continue;
      }
      if (loanId == null || !validLoanIds.contains(loanId)) {
        errors.add('Lần trả nợ có khoản vay không hợp lệ — bỏ qua');
        loanPaymentsSkipped++;
        continue;
      }
      if (existingLoanPaymentIds.contains(id)) {
        loanPaymentsSkipped++;
        continue;
      }
      loanPaymentsAdded++;
      if (!dryRun) {
        await _insertLoanPayment(payment, execute!);
        existingLoanPaymentIds.add(id);
      }
    }

    for (final installment in rawLoanInstallments) {
      final id = installment['id'] as String?;
      final loanId = installment['loan_id'] as String?;
      if (id == null || id.isEmpty) {
        errors.add('Đợt trả góp thiếu id');
        continue;
      }
      if (loanId == null || !validLoanIds.contains(loanId)) {
        errors.add('Đợt trả góp có khoản vay không hợp lệ — bỏ qua');
        loanInstallmentsSkipped++;
        continue;
      }
      if (existingLoanInstallmentIds.contains(id)) {
        loanInstallmentsSkipped++;
        continue;
      }
      loanInstallmentsAdded++;
      if (!dryRun) {
        await _insertLoanInstallment(installment, execute!);
        existingLoanInstallmentIds.add(id);
      }
    }

    // ── Wallets (restore trước để tx có thể ref) ────────────────────────────
    final backupWalletIds = <String>{};
    for (final w in rawWallets) {
      final id = w['id'] as String?;
      if (id == null || id.isEmpty) {
        errors.add('Wallet thiếu id: ${w['name']}');
        continue;
      }
      backupWalletIds.add(id);
      if (existingWalletIds.contains(id)) {
        walletsSkipped++;
      } else {
        walletsAdded++;
        if (!dryRun) {
          await _insertWallet(w, execute!);
          existingWalletIds.add(id);
        }
      }
    }

    // ── Categories ──────────────────────────────────────────────────────────
    for (final cat in rawCats) {
      final id = cat['id'] as String?;
      if (id == null || id.isEmpty) {
        errors.add('Category thiếu id: ${cat['name']}');
        continue;
      }
      if (existingCatIds.contains(id)) {
        catsSkipped++;
      } else {
        catsAdded++;
        if (!dryRun) {
          await _insertCategory(cat, execute!);
          existingCatIds.add(id);
        }
      }
    }

    // ── Transactions ────────────────────────────────────────────────────────
    final backupCatIds = rawCats.map((c) => c['id'] as String).toSet();
    final validCatIds = {...existingCatIds, ...backupCatIds};
    final validWalletIds = {...existingWalletIds, ...backupWalletIds};

    for (int i = 0; i < rawTxs.length; i++) {
      final tx = rawTxs[i];
      final id = tx['id'] as String?;
      if (id == null || id.isEmpty) {
        errors.add('Transaction dòng $i thiếu id');
        continue;
      }

      final catId = tx['category_id'] as String?;
      if (catId == null || !validCatIds.contains(catId)) {
        errors.add(
            'Transaction "${tx['note'] ?? id.substring(0, 8)}" có category không hợp lệ — bỏ qua');
        txsSkipped++;
        continue;
      }

      // wallet_id nullable — nếu có thì phải hợp lệ
      final walletId = tx['wallet_id'] as String?;
      if (walletId != null &&
          walletId.isNotEmpty &&
          !validWalletIds.contains(walletId)) {
        errors.add(
            'Transaction "${tx['note'] ?? id.substring(0, 8)}" có wallet không hợp lệ — gỡ liên kết');
        // Vẫn restore nhưng không gắn wallet
        tx['wallet_id'] = null;
      }

      if (existingTxIds.contains(id)) {
        txsSkipped++;
      } else {
        txsAdded++;
        if (!dryRun) {
          await _insertTransaction(tx, execute!);
          existingTxIds.add(id);
        }
      }
    }

    // ── Reminders ───────────────────────────────────────────────────────────
    for (final rem in rawReminders) {
      final id = rem['id'] as String?;
      if (id == null || id.isEmpty) {
        errors.add('Reminder thiếu id: ${rem['title']}');
        continue;
      }
      final catId = rem['category_id'] as String?;
      if (catId == null || !validCatIds.contains(catId)) {
        errors.add('Reminder "${rem['title']}" có category không hợp lệ — bỏ qua');
        remindersSkipped++;
        continue;
      }
      if (existingReminderIds.contains(id)) {
        remindersSkipped++;
      } else {
        remindersAdded++;
        if (!dryRun) {
          await _insertReminder(rem, execute!);
          existingReminderIds.add(id);
        }
      }
    }

    // ── Category budgets ────────────────────────────────────────────────────
    for (final bud in rawBudgets) {
      final catId = bud['category_id'] as String?;
      if (catId == null || !validCatIds.contains(catId)) {
        errors.add('Budget có category không hợp lệ — bỏ qua');
        budgetsSkipped++;
        continue;
      }
      if (existingBudgetCatIds.contains(catId)) {
        budgetsSkipped++;
      } else {
        budgetsAdded++;
        if (!dryRun) {
          await _insertBudget(bud, execute!);
          existingBudgetCatIds.add(catId);
        }
      }
    }

    // ── Monthly budgets ────────────────────────────────────────────────────
    for (final budget in rawMonthlyBudgets) {
      final id = budget['id'] as String?;
      final month = budget['month'] as String?;
      if (id == null || id.isEmpty || month == null || month.isEmpty) {
        errors.add('Ngân sách tháng thiếu id hoặc month — bỏ qua');
        continue;
      }
      if (existingMonthlyBudgetIds.contains(id) ||
          existingMonthlyBudgetMonths.contains(month)) {
        monthlyBudgetsSkipped++;
        continue;
      }
      monthlyBudgetsAdded++;
      if (!dryRun) {
        await _insertMonthlyBudget(budget, execute!);
        existingMonthlyBudgetIds.add(id);
        existingMonthlyBudgetMonths.add(month);
      }
    }

    return RestoreResult(
      categoriesAdded: catsAdded,
      transactionsAdded: txsAdded,
      categoriesSkipped: catsSkipped,
      transactionsSkipped: txsSkipped,
      remindersAdded: remindersAdded,
      remindersSkipped: remindersSkipped,
      budgetsAdded: budgetsAdded,
      budgetsSkipped: budgetsSkipped,
      walletsAdded: walletsAdded,
      walletsSkipped: walletsSkipped,
      monthlyBudgetsAdded: monthlyBudgetsAdded,
      monthlyBudgetsSkipped: monthlyBudgetsSkipped,
      loansAdded: loansAdded,
      loansSkipped: loansSkipped,
      loanPaymentsAdded: loanPaymentsAdded,
      loanPaymentsSkipped: loanPaymentsSkipped,
      loanInstallmentsAdded: loanInstallmentsAdded,
      loanInstallmentsSkipped: loanInstallmentsSkipped,
      errors: errors,
    );
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  // ── DB helpers ──────────────────────────────────────────────────────────────

  static Future<Set<String>> _getExistingCategoryIds([_RowReader? readRows]) async {
    final rows = readRows == null
        ? await db.getAll('SELECT id FROM categories')
        : await readRows('SELECT id FROM categories');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingTransactionIds([_RowReader? readRows]) async {
    final rows = readRows == null
        ? await db.getAll('SELECT id FROM transactions')
        : await readRows('SELECT id FROM transactions');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingReminderIds([_RowReader? readRows]) async {
    final rows = readRows == null
        ? await db.getAll('SELECT id FROM recurring_reminders')
        : await readRows('SELECT id FROM recurring_reminders');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingBudgetCategoryIds([_RowReader? readRows]) async {
    final rows = readRows == null
        ? await db.getAll('SELECT category_id FROM category_budgets')
        : await readRows('SELECT category_id FROM category_budgets');
    return rows.map((r) => r['category_id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingWalletIds([_RowReader? readRows]) async {
    final rows = readRows == null
        ? await db.getAll('SELECT id FROM wallets')
        : await readRows('SELECT id FROM wallets');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingMonthlyBudgetIds([_RowReader? readRows]) async {
    final rows = readRows == null
        ? await db.getAll('SELECT id FROM budgets')
        : await readRows('SELECT id FROM budgets');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingMonthlyBudgetMonths([_RowReader? readRows]) async {
    final rows = readRows == null
        ? await db.getAll('SELECT month FROM budgets')
        : await readRows('SELECT month FROM budgets');
    return rows.map((r) => r['month'] as String).toSet();
  }

  static Future<void> _insertWallet(
    Map<String, dynamic> w,
    _SqlExecutor execute,
  ) async {
    await execute(
      '''INSERT INTO wallets(id, name, type, initial_balance, note, color_hex, sort_order, is_archived)
         VALUES(?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        w['id'] as String,
        w['name'] as String,
        w['type'] as String,
        (w['initial_balance'] as int).toString(),
        w['note'] as String?,
        w['color_hex'] as String,
        w['sort_order'] as int,
        (w['is_archived'] as bool) ? 1 : 0,
      ],
    );
  }

  static Future<void> _insertCategory(
    Map<String, dynamic> cat,
    _SqlExecutor execute,
  ) async {
    await execute(
      '''INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order)
         VALUES(?, ?, ?, ?, ?, ?, ?)''',
      [
        cat['id'] as String,
        cat['name'] as String,
        cat['color_hex'] as String,
        cat['icon_name'] as String,
        (cat['is_default'] as bool? ?? false) ? 1 : 0,
        (cat['is_income'] as bool) ? 1 : 0,
        cat['sort_order'] as int,
      ],
    );
  }

  static Future<void> _insertTransaction(
    Map<String, dynamic> tx,
    _SqlExecutor execute,
  ) async {
    await execute(
      '''INSERT INTO transactions(id, amount, type, category_id, note, created_at, wallet_id, source)
         VALUES(?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        tx['id'] as String,
        (tx['amount'] as int).toString(),
        tx['type'] as String,
        tx['category_id'] as String,
        tx['note'] as String?,
        (tx['created_at'] as int).toString(),
        tx['wallet_id'] as String?,
        tx['source'] as String? ?? 'manual',
      ],
    );
  }

  static Future<void> _insertReminder(
    Map<String, dynamic> rem,
    _SqlExecutor execute,
  ) async {
    await execute(
      '''INSERT INTO recurring_reminders(
          id, title, category_id, amount_hint, frequency,
          day_of_week, day_of_month, hour, minute,
          is_active, next_trigger, warn_before_hours
        ) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        rem['id'] as String,
        rem['title'] as String,
        rem['category_id'] as String,
        rem['amount_hint']?.toString(),
        rem['frequency'] as String,
        rem['day_of_week'] as int?,
        rem['day_of_month'] as int?,
        rem['hour'] as int,
        rem['minute'] as int,
        (rem['is_active'] as bool) ? 1 : 0,
        rem['next_trigger'] as String,
        (rem['warn_before_hours'] as int?) ?? 0,
      ],
    );
  }

  static Future<void> _insertBudget(
    Map<String, dynamic> bud,
    _SqlExecutor execute,
  ) async {
    await execute(
      '''INSERT INTO category_budgets(id, category_id, amount)
         VALUES(?, ?, ?)''',
      [
        bud['id'] as String,
        bud['category_id'] as String,
        (bud['amount'] as int).toString(),
      ],
    );
  }

  static Future<void> _insertMonthlyBudget(
    Map<String, dynamic> budget,
    _SqlExecutor execute,
  ) async {
    await execute('INSERT INTO budgets(id, amount, month) VALUES(?, ?, ?)', [
      budget['id'] as String,
      (budget['amount'] as int).toString(),
      budget['month'] as String,
    ]);
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return result?.files.single.path;
  }

  static Future<Set<String>> _getExistingLoanIds([_RowReader? readRows]) async {
    final rows = readRows == null
        ? await db.getAll('SELECT id FROM loans')
        : await readRows('SELECT id FROM loans');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingLoanPaymentIds([_RowReader? readRows]) async {
    final rows = readRows == null
        ? await db.getAll('SELECT id FROM loan_payments')
        : await readRows('SELECT id FROM loan_payments');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingLoanInstallmentIds([
    _RowReader? readRows,
  ]) async {
    final rows = readRows == null
        ? await db.getAll('SELECT id FROM loan_installments')
        : await readRows('SELECT id FROM loan_installments');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<void> _insertLoan(
    Map<String, dynamic> l,
    _SqlExecutor execute,
  ) async {
    await execute(
      '''INSERT INTO loans(id, title, type, principal, contact_name,
           start_date, due_date, note, color_hex, is_closed, repayment_mode,
           funding_transaction_id, is_tracking_only)
         VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        l['id'], l['title'], l['type'],
        (l['principal'] as int).toString(),
        l['contact_name'] ?? '',
        l['start_date'], l['due_date'], l['note'],
        l['color_hex'], (l['is_closed'] as bool) ? 1 : 0,
        // A backup written before schedules existed carries neither field;
        // both are nullable and a missing mode reads as free repayment.
        l['repayment_mode'],
        l['funding_transaction_id'],
        // Absent in every backup written before the tracking book: a loan
        // restored from one belongs to the spending book, as it always did.
        (l['is_tracking_only'] as bool? ?? false) ? 1 : 0,
      ],
    );
  }

  static Future<void> _insertLoanInstallment(
    Map<String, dynamic> installment,
    _SqlExecutor execute,
  ) async {
    await execute(
      '''INSERT INTO loan_installments(id, loan_id, seq, amount, due_date)
         VALUES(?, ?, ?, ?, ?)''',
      [
        installment['id'] as String,
        installment['loan_id'] as String,
        installment['seq'] as int,
        (installment['amount'] as int).toString(),
        installment['due_date'] as String,
      ],
    );
  }

  static Future<void> _insertLoanPayment(
    Map<String, dynamic> payment,
    _SqlExecutor execute,
  ) async {
    await execute(
      '''INSERT INTO loan_payments(id, loan_id, amount, paid_at, note,
           transaction_id)
         VALUES(?, ?, ?, ?, ?, ?)''',
      [
        payment['id'] as String,
        payment['loan_id'] as String,
        (payment['amount'] as int).toString(),
        payment['paid_at'] as String,
        payment['note'] as String?,
        payment['transaction_id'] as String?,
      ],
    );
  }
}

class _RestorePayload {
  const _RestorePayload({
    required this.wallets,
    required this.categories,
    required this.loans,
    required this.loanPayments,
    required this.loanInstallments,
    required this.transactions,
    required this.reminders,
    required this.categoryBudgets,
    required this.monthlyBudgets,
  });

  factory _RestorePayload.fromJson(Map<String, dynamic> data) {
    if (data['app'] != _kBackupAppTag) {
      throw const FormatException('File không phải backup Spendo');
    }
    final version = data['version'];
    if (version is! int) {
      throw const FormatException('File thiếu hoặc sai trường version');
    }
    if (version > _kBackupVersion) {
      throw FormatException(
        'File được tạo từ phiên bản Spendo mới hơn (v$version), vui lòng cập nhật app',
      );
    }

    final wallets = _rows(data, 'wallets');
    final categories = _rows(data, 'categories', required: true);
    final loans = _rows(data, 'loans');
    final loanPayments = _rows(data, 'loan_payments');
    final loanInstallments = _rows(data, 'loan_installments');
    final transactions = _rows(data, 'transactions', required: true);
    final reminders = _rows(data, 'recurring_reminders');
    final categoryBudgets = _rows(data, 'category_budgets');
    final monthlyBudgets = _rows(data, 'budgets');

    _validateRows(wallets, 'wallets', {
      'id': String,
      'name': String,
      'type': String,
      'initial_balance': int,
      'color_hex': String,
      'sort_order': int,
      'is_archived': bool,
    });
    _validateNullableRows(wallets, 'wallets', {'note': String});
    _validateRows(categories, 'categories', {
      'id': String,
      'name': String,
      'color_hex': String,
      'icon_name': String,
      'is_income': bool,
      'sort_order': int,
    });
    _validateNullableRows(categories, 'categories', {'is_default': bool});
    _validateRows(loans, 'loans', {
      'id': String,
      'title': String,
      'type': String,
      'principal': int,
      'start_date': String,
      'color_hex': String,
      'is_closed': bool,
    });
    _validateNullableRows(loans, 'loans', {
      'contact_name': String,
      'due_date': String,
      'note': String,
      // Absent in every backup written before schedules; nullable, so an old
      // file restores with a free-repayment loan and no funding transaction.
      'repayment_mode': String,
      'funding_transaction_id': String,
      'is_tracking_only': bool,
    });
    _validateDates(loans, 'loans', 'start_date');
    _validateDates(loans, 'loans', 'due_date', nullable: true);
    _validateRows(loanPayments, 'loan_payments', {
      'id': String,
      'loan_id': String,
      'amount': int,
      'paid_at': String,
    });
    _validateNullableRows(loanPayments, 'loan_payments', {
      'note': String,
      'transaction_id': String,
    });
    _validateDates(loanPayments, 'loan_payments', 'paid_at');
    _validateRows(loanInstallments, 'loan_installments', {
      'id': String,
      'loan_id': String,
      'seq': int,
      'amount': int,
      'due_date': String,
    });
    _validateDates(loanInstallments, 'loan_installments', 'due_date');
    _validateRows(transactions, 'transactions', {
      'id': String,
      'amount': int,
      'type': String,
      'category_id': String,
      'created_at': int,
    });
    _validateNullableRows(transactions, 'transactions', {
      'note': String,
      'wallet_id': String,
      'source': String,
    });
    _validateRows(reminders, 'recurring_reminders', {
      'id': String,
      'title': String,
      'category_id': String,
      'frequency': String,
      'hour': int,
      'minute': int,
      'is_active': bool,
      'next_trigger': String,
    });
    _validateNullableRows(reminders, 'recurring_reminders', {
      'amount_hint': int,
      'day_of_week': int,
      'day_of_month': int,
      'warn_before_hours': int,
    });
    _validateDates(reminders, 'recurring_reminders', 'next_trigger');
    _validateRows(categoryBudgets, 'category_budgets', {
      'id': String,
      'category_id': String,
      'amount': int,
    });
    _validateRows(monthlyBudgets, 'budgets', {
      'id': String,
      'amount': int,
      'month': String,
    });

    return _RestorePayload(
      wallets: wallets,
      categories: categories,
      loans: loans,
      loanPayments: loanPayments,
      loanInstallments: loanInstallments,
      transactions: transactions,
      reminders: reminders,
      categoryBudgets: categoryBudgets,
      monthlyBudgets: monthlyBudgets,
    );
  }

  final List<Map<String, dynamic>> wallets;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> loans;
  final List<Map<String, dynamic>> loanPayments;
  final List<Map<String, dynamic>> loanInstallments;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> reminders;
  final List<Map<String, dynamic>> categoryBudgets;
  final List<Map<String, dynamic>> monthlyBudgets;

  static List<Map<String, dynamic>> _rows(
    Map<String, dynamic> data,
    String key, {
    bool required = false,
  }) {
    final value = data[key];
    if (value == null && !required) return <Map<String, dynamic>>[];
    if (value is! List) {
      throw FormatException('File hỏng — trường $key phải là danh sách');
    }
    return List<Map<String, dynamic>>.generate(value.length, (index) {
      final row = value[index];
      if (row is! Map<String, dynamic>) {
        throw FormatException('File hỏng — $key[$index] không phải object');
      }
      return Map<String, dynamic>.from(row);
    });
  }

  static void _validateRows(
    List<Map<String, dynamic>> rows,
    String listName,
    Map<String, Type> fields,
  ) {
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      for (final field in fields.entries) {
        final value = row[field.key];
        if (value == null || value.runtimeType != field.value) {
          throw FormatException(
            'File hỏng — $listName[$index].${field.key} sai kiểu hoặc bị thiếu',
          );
        }
      }
    }
  }

  static void _validateNullableRows(
    List<Map<String, dynamic>> rows,
    String listName,
    Map<String, Type> fields,
  ) {
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      for (final field in fields.entries) {
        final value = row[field.key];
        if (value != null && value.runtimeType != field.value) {
          throw FormatException(
            'File hỏng — $listName[$index].${field.key} sai kiểu',
          );
        }
      }
    }
  }

  static void _validateDates(
    List<Map<String, dynamic>> rows,
    String listName,
    String field, {
    bool nullable = false,
  }) {
    for (var index = 0; index < rows.length; index++) {
      final value = rows[index][field];
      if (value == null && nullable) continue;
      if (value is! String || DateTime.tryParse(value) == null) {
        throw FormatException(
          'File hỏng — $listName[$index].$field không phải ngày hợp lệ',
        );
      }
    }
  }
}
