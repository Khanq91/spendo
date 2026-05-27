import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/budget/data/category_budget_repository.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/reminders/data/reminder_repository.dart';
import '../../features/transactions/data/transaction_repository.dart';
import '../db/powersync_db.dart';

// ── Backup result ─────────────────────────────────────────────────────────────

class BackupResult {
  final int categories;
  final int transactions;
  final int reminders;
  final int categoryBudgets;
  final List<String> errors;

  const BackupResult({
    required this.categories,
    required this.transactions,
    this.reminders = 0,
    this.categoryBudgets = 0,
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
    this.errors = const [],
  });
}

// ── Backup format version ─────────────────────────────────────────────────────
//
// {
//   "version": 1,
//   "app": "spendo",
//   "exported_at": 1715000000000,   // epoch ms UTC
//   "categories": [
//     {
//       "id": "uuid",
//       "name": "Ăn uống",
//       "color_hex": "#FF6B6B",
//       "icon_name": "restaurant",
//       "is_income": false,
//       "sort_order": 0
//     }
//   ],
//   "transactions": [
//     {
//       "id": "uuid",
//       "amount": 50000,
//       "type": "expense",
//       "category_id": "uuid",
//       "note": "bún bò",           // nullable
//       "created_at": 1714903800000  // epoch ms
//     }
//   ]
// }

const _kBackupVersion = 2;
const _kBackupAppTag = 'spendo';

class BackupService {
  // ── Export ──────────────────────────────────────────────────────────────────

  static Future<BackupResult> exportBackup() async {
    final catRepo = CategoryRepository();
    final txRepo = TransactionRepository();
    final reminderRepo = ReminderRepository();
    final budgetRepo = CategoryBudgetRepository();

    final categories = await catRepo.getAll();
    final transactions = await txRepo.getAll();
    final reminders = await reminderRepo.getAll();
    final budgets = await budgetRepo.getAll();

    final payload = {
      'version': _kBackupVersion,
      'app': _kBackupAppTag,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
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
    };

    final json = const JsonEncoder.withIndent('  ').convert(payload);

    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName =
        'spendo_backup_${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Spendo — Backup dữ liệu',
    );

    return BackupResult(
      categories: categories.length,
      transactions: transactions.length,
      reminders: reminders.length,
      categoryBudgets: budgets.length,
    );
  }

  // ── Export as string (for Google Drive) ──────────────────────────────────────

  /// Export backup data as a JSON string without sharing.
  /// Used by GDriveBackupService to upload to Google Drive.
  static Future<String> exportBackupAsString() async {
    final catRepo = CategoryRepository();
    final txRepo = TransactionRepository();
    final reminderRepo = ReminderRepository();
    final budgetRepo = CategoryBudgetRepository();

    final categories = await catRepo.getAll();
    final transactions = await txRepo.getAll();
    final reminders = await reminderRepo.getAll();
    final budgets = await budgetRepo.getAll();

    final payload = {
      'version': _kBackupVersion,
      'app': _kBackupAppTag,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
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
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  // ── Preview (dry-run) ───────────────────────────────────────────────────────

  static Future<RestoreResult> previewRestore(String filePath) async {
    return _processRestore(filePath, dryRun: true);
  }

  // ── Restore ─────────────────────────────────────────────────────────────────

  static Future<RestoreResult> restore(String filePath) async {
    return _processRestore(filePath, dryRun: false);
  }

  // ── Core logic ──────────────────────────────────────────────────────────────

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

    // Parse JSON
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

    // Validate
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

    final rawCats = (data['categories'] as List).cast<Map<String, dynamic>>();
    final rawTxs =
    (data['transactions'] as List).cast<Map<String, dynamic>>();
    final rawReminders = data['recurring_reminders'] is List
        ? (data['recurring_reminders'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final rawBudgets = data['category_budgets'] is List
        ? (data['category_budgets'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    // Load existing IDs để detect trùng
    final existingCatIds = await _getExistingCategoryIds();
    final existingTxIds = await _getExistingTransactionIds();
    final existingReminderIds = await _getExistingReminderIds();
    final existingBudgetCatIds = await _getExistingBudgetCategoryIds();

    int catsAdded = 0;
    int catsSkipped = 0;
    int txsAdded = 0;
    int txsSkipped = 0;
    int remindersAdded = 0;
    int remindersSkipped = 0;
    int budgetsAdded = 0;
    int budgetsSkipped = 0;
    final errors = <String>[];

    // ── Process categories ──────────────────────────────────────────────────

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
          existingCatIds.add(id); // track trong session để tránh dup trong file
        }
      }
    }

    // ── Process transactions ────────────────────────────────────────────────

    // Collect all category IDs from backup (để check orphan transactions)
    final backupCatIds = rawCats.map((c) => c['id'] as String).toSet();
    // Sau restore, category IDs hợp lệ = existing + vừa thêm
    final validCatIds = {...existingCatIds, ...backupCatIds};

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

    // ── Process recurring reminders ─────────────────────────────────────────

    for (final rem in rawReminders) {
      final id = rem['id'] as String?;
      if (id == null || id.isEmpty) {
        errors.add('Reminder thiếu id: ${rem['title']}');
        continue;
      }

      final catId = rem['category_id'] as String?;
      if (catId == null || !validCatIds.contains(catId)) {
        errors.add(
            'Reminder "${rem['title']}" có category không hợp lệ — bỏ qua');
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

    // ── Process category budgets ────────────────────────────────────────────

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
      errors: errors,
    );
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  static String? _validate(Map<String, dynamic> data) {
    if (data['app'] != _kBackupAppTag) {
      return 'File không phải backup Spendo';
    }
    if (data['version'] == null) {
      return 'File thiếu trường version';
    }
    final version = data['version'] as int;
    if (version > _kBackupVersion) {
      return 'File được tạo từ phiên bản Spendo mới hơn (v$version), vui lòng cập nhật app';
    }
    if (data['categories'] is! List) {
      return 'File hỏng — thiếu danh sách categories';
    }
    if (data['transactions'] is! List) {
      return 'File hỏng — thiếu danh sách transactions';
    }
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
      '''INSERT INTO transactions(id, amount, type, category_id, note, created_at)
         VALUES(?, ?, ?, ?, ?, ?)''',
      [
        tx['id'] as String,
        (tx['amount'] as int).toString(),
        tx['type'] as String,
        tx['category_id'] as String,
        tx['note'] as String?,
        (tx['created_at'] as int).toString(),
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

  // ── File picker helper ──────────────────────────────────────────────────────

  static Future<String?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return result?.files.single.path;
  }
}