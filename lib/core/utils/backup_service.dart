import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/transactions/data/transaction_repository.dart';
import '../db/powersync_db.dart';

// ── Backup result ─────────────────────────────────────────────────────────────

class BackupResult {
  final int categories;
  final int transactions;
  final List<String> errors;

  const BackupResult({
    required this.categories,
    required this.transactions,
    this.errors = const [],
  });
}

class RestoreResult {
  final int categoriesAdded;
  final int transactionsAdded;
  final int categoriesSkipped;
  final int transactionsSkipped;
  final List<String> errors;

  const RestoreResult({
    required this.categoriesAdded,
    required this.transactionsAdded,
    required this.categoriesSkipped,
    required this.transactionsSkipped,
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

const _kBackupVersion = 1;
const _kBackupAppTag = 'spendo';

class BackupService {
  // ── Export ──────────────────────────────────────────────────────────────────

  static Future<BackupResult> exportBackup() async {
    final catRepo = CategoryRepository();
    final txRepo = TransactionRepository();

    final categories = await catRepo.getAll();
    final transactions = await txRepo.getAll();

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
    );
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

    // Load existing IDs để detect trùng
    final existingCatIds = await _getExistingCategoryIds();
    final existingTxIds = await _getExistingTransactionIds();

    int catsAdded = 0;
    int catsSkipped = 0;
    int txsAdded = 0;
    int txsSkipped = 0;
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

    return RestoreResult(
      categoriesAdded: catsAdded,
      transactionsAdded: txsAdded,
      categoriesSkipped: catsSkipped,
      transactionsSkipped: txsSkipped,
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