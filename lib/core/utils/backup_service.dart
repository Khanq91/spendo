import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  final int wallets;
  final List<String> errors;

  const BackupResult({
    required this.categories,
    required this.transactions,
    this.reminders = 0,
    this.categoryBudgets = 0,
    this.wallets = 0,
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
    this.errors = const [],
  });
}

// ── Version ───────────────────────────────────────────────────────────────────

const _kBackupVersion = 3;
const _kBackupAppTag = 'spendo';

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
    final walletRepo = WalletRepository();

    return BackupResult(
      categories: (await catRepo.getAll()).length,
      transactions: (await txRepo.getAll()).length,
      reminders: (await reminderRepo.getAll()).length,
      categoryBudgets: (await budgetRepo.getAll()).length,
      wallets: (await walletRepo.getAll()).length,
    );
  }

  static Future<String> exportBackupAsString() async {
    final catRepo = CategoryRepository();
    final txRepo = TransactionRepository();
    final reminderRepo = ReminderRepository();
    final budgetRepo = CategoryBudgetRepository();
    final walletRepo = WalletRepository();
    final loanRepo = LoanRepository();

    final loans = await loanRepo.getAll();
    final categories = await catRepo.getAll();
    final transactions = await txRepo.getAll();
    final reminders = await reminderRepo.getAll();
    final budgets = await budgetRepo.getAll();
    final wallets = await walletRepo.getAll();

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
          }).toList(),
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

    final validationError = _validate(data);
    if (validationError != null) {
      return RestoreResult(
        categoriesAdded: 0,
        transactionsAdded: 0,
        categoriesSkipped: 0,
        transactionsSkipped: 0,
        errors: [validationError],
      );
    }

    final rawWallets = data['wallets'] is List
        ? (data['wallets'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final rawCats =
        (data['categories'] as List).cast<Map<String, dynamic>>();
    final rawLoans = data['loans'] is List
        ? (data['loans'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final rawTxs =
        (data['transactions'] as List).cast<Map<String, dynamic>>();
    final rawReminders = data['recurring_reminders'] is List
        ? (data['recurring_reminders'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final rawBudgets = data['category_budgets'] is List
        ? (data['category_budgets'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    final existingCatIds = await _getExistingCategoryIds();
    final existingTxIds = await _getExistingTransactionIds();
    final existingReminderIds = await _getExistingReminderIds();
    final existingBudgetCatIds = await _getExistingBudgetCategoryIds();
    final existingWalletIds = await _getExistingWalletIds();
    final existingLoanIds = await _getExistingLoanIds();

    int catsAdded = 0, catsSkipped = 0;
    int txsAdded = 0, txsSkipped = 0;
    int remindersAdded = 0, remindersSkipped = 0;
    int budgetsAdded = 0, budgetsSkipped = 0;
    int walletsAdded = 0, walletsSkipped = 0;
    int loansAdded = 0, loansSkipped = 0;
    final errors = <String>[];

    for (final l in rawLoans) {
      final id = l['id'] as String?;
      if (id == null) continue;
      if (existingLoanIds.contains(id)) { loansSkipped++; continue; }
      loansAdded++;
      if (!dryRun) await _insertLoan(l);
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
          await _insertWallet(w);
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
          await _insertCategory(cat);
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
          await _insertTransaction(tx);
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
          await _insertReminder(rem);
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
          await _insertBudget(bud);
          existingBudgetCatIds.add(catId);
        }
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
      errors: errors,
    );
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  static String? _validate(Map<String, dynamic> data) {
    if (data['app'] != _kBackupAppTag) return 'File không phải backup Spendo';
    if (data['version'] == null) return 'File thiếu trường version';
    final version = data['version'] as int;
    if (version > _kBackupVersion) {
      return 'File được tạo từ phiên bản Spendo mới hơn (v$version), vui lòng cập nhật app';
    }
    if (data['categories'] is! List) return 'File hỏng — thiếu danh sách categories';
    if (data['transactions'] is! List) return 'File hỏng — thiếu danh sách transactions';
    return null;
  }

  // ── DB helpers ──────────────────────────────────────────────────────────────

  static Future<Set<String>> _getExistingCategoryIds() async {
    final rows = await db.getAll('SELECT id FROM categories');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingTransactionIds() async {
    final rows = await db.getAll('SELECT id FROM transactions');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingReminderIds() async {
    final rows = await db.getAll('SELECT id FROM recurring_reminders');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingBudgetCategoryIds() async {
    final rows = await db.getAll('SELECT category_id FROM category_budgets');
    return rows.map((r) => r['category_id'] as String).toSet();
  }

  static Future<Set<String>> _getExistingWalletIds() async {
    final rows = await db.getAll('SELECT id FROM wallets');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<void> _insertWallet(Map<String, dynamic> w) async {
    await db.execute(
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

  static Future<void> _insertCategory(Map<String, dynamic> cat) async {
    await db.execute(
      '''INSERT INTO categories(id, name, color_hex, icon_name, is_default, is_income, sort_order)
         VALUES(?, ?, ?, ?, 0, ?, ?)''',
      [
        cat['id'] as String,
        cat['name'] as String,
        cat['color_hex'] as String,
        cat['icon_name'] as String,
        (cat['is_income'] as bool) ? 1 : 0,
        cat['sort_order'] as int,
      ],
    );
  }

  static Future<void> _insertTransaction(Map<String, dynamic> tx) async {
    await db.execute(
      '''INSERT INTO transactions(id, amount, type, category_id, note, created_at, wallet_id)
         VALUES(?, ?, ?, ?, ?, ?, ?)''',
      [
        tx['id'] as String,
        (tx['amount'] as int).toString(),
        tx['type'] as String,
        tx['category_id'] as String,
        tx['note'] as String?,
        (tx['created_at'] as int).toString(),
        tx['wallet_id'] as String?,
      ],
    );
  }

  static Future<void> _insertReminder(Map<String, dynamic> rem) async {
    await db.execute(
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

  static Future<void> _insertBudget(Map<String, dynamic> bud) async {
    await db.execute(
      '''INSERT INTO category_budgets(id, category_id, amount)
         VALUES(?, ?, ?)''',
      [
        bud['id'] as String,
        bud['category_id'] as String,
        (bud['amount'] as int).toString(),
      ],
    );
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return result?.files.single.path;
  }

  static Future<Set<String>> _getExistingLoanIds() async {
    final rows = await db.getAll('SELECT id FROM loans');
    return rows.map((r) => r['id'] as String).toSet();
  }

  static Future<void> _insertLoan(Map<String, dynamic> l) async {
    await db.execute(
      '''INSERT INTO loans(id, title, type, principal, contact_name,
           start_date, due_date, note, color_hex, is_closed)
         VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        l['id'], l['title'], l['type'],
        (l['principal'] as int).toString(),
        l['contact_name'] ?? '',
        l['start_date'], l['due_date'], l['note'],
        l['color_hex'], (l['is_closed'] as bool) ? 1 : 0,
      ],
    );
  }
}
