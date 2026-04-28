import 'dart:io';
import 'package:csv/csv.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/transactions/data/transaction_repository.dart';

/// Kết quả import CSV
class ImportResult {
  final int added;
  final int skipped;
  final int newCategories;
  final List<String> newCategoryNames;
  final List<String> errors;

  const ImportResult({
    required this.added,
    required this.skipped,
    required this.newCategories,
    required this.newCategoryNames,
    required this.errors,
  });
}

class ImportService {
  /// Chỉ phân tích file CSV, trả kết quả preview (KHÔNG ghi DB).
  static Future<ImportResult> previewCSV(String filePath) async {
    return _processCSV(filePath, dryRun: true);
  }

  /// Parse + dedup + insert thật vào DB.
  static Future<ImportResult> importCSV(String filePath) async {
    return _processCSV(filePath, dryRun: false);
  }

  static Future<ImportResult> _processCSV(
      String filePath, {
        required bool dryRun,
      }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const ImportResult(
        added: 0,
        skipped: 0,
        newCategories: 0,
        newCategoryNames: [],
        errors: ['File không tồn tại'],
      );
    }

    // Đọc file, xử lý BOM marker
    String content = await file.readAsString();
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    // Parse CSV
    final rows = const CsvToListConverter().convert(content);
    if (rows.isEmpty) {
      return const ImportResult(
        added: 0,
        skipped: 0,
        newCategories: 0,
        newCategoryNames: [],
        errors: ['File CSV trống'],
      );
    }

    // Validate header
    final header = rows.first.map((e) => e.toString().trim()).toList();
    const expectedHeader = ['Ngày', 'Loại', 'Danh mục', 'Số tiền', 'Ghi chú'];
    if (header.length < 5 ||
        header[0] != expectedHeader[0] ||
        header[1] != expectedHeader[1] ||
        header[2] != expectedHeader[2] ||
        header[3] != expectedHeader[3] ||
        header[4] != expectedHeader[4]) {
      return const ImportResult(
        added: 0,
        skipped: 0,
        newCategories: 0,
        newCategoryNames: [],
        errors: ['File CSV không đúng format Spendo (sai header)'],
      );
    }

    final dataRows = rows.skip(1).toList();
    if (dataRows.isEmpty) {
      return const ImportResult(
        added: 0,
        skipped: 0,
        newCategories: 0,
        newCategoryNames: [],
        errors: ['File CSV không có dữ liệu (chỉ có header)'],
      );
    }

    // Load dữ liệu hiện có
    final catRepo = CategoryRepository();
    final txRepo = TransactionRepository();
    final existingCats = await catRepo.getAll();
    final existingTxs = await txRepo.getAll();

    // Build fingerprint set từ transactions hiện có
    final existingFingerprints = <String>{};
    for (final tx in existingTxs) {
      existingFingerprints.add(_fingerprint(
        createdAt: tx.createdAt,
        type: tx.type,
        categoryId: tx.categoryId,
        amount: tx.amount,
        note: tx.note ?? '',
      ));
    }

    // Cache tên → category (key = "name|isIncome")
    final catCache = <String, String>{};
    for (final c in existingCats) {
      catCache['${c.name}|${c.isIncome}'] = c.id;
    }

    int added = 0;
    int skipped = 0;
    final newCategoryNames = <String>[];
    final errors = <String>[];
    final toInsert = <Map<String, dynamic>>[];

    for (int i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final lineNum = i + 2; // +2 vì header + 1-indexed

      try {
        if (row.length < 5) {
          errors.add('Dòng $lineNum: thiếu cột (cần 5, có ${row.length})');
          continue;
        }

        final dateStr = row[0].toString().trim();
        final typeStr = row[1].toString().trim();
        final catName = row[2].toString().trim();
        final amountRaw = row[3];
        final note = row[4].toString().trim();

        // Parse date: "d/M/yyyy HH:mm"
        final date = _parseDate(dateStr);
        if (date == null) {
          errors.add('Dòng $lineNum: không parse được ngày "$dateStr"');
          continue;
        }

        // Parse type
        final String type;
        if (typeStr == 'Chi') {
          type = 'expense';
        } else if (typeStr == 'Thu') {
          type = 'income';
        } else {
          errors.add('Dòng $lineNum: loại "$typeStr" không hợp lệ (cần Chi/Thu)');
          continue;
        }

        // Parse amount
        final int amount;
        if (amountRaw is int) {
          amount = amountRaw;
        } else if (amountRaw is double) {
          amount = amountRaw.toInt();
        } else {
          final parsed = int.tryParse(amountRaw.toString().trim());
          if (parsed == null) {
            errors.add('Dòng $lineNum: số tiền "$amountRaw" không hợp lệ');
            continue;
          }
          amount = parsed;
        }

        // Tìm / tạo category
        final isIncome = type == 'income';
        final cacheKey = '$catName|$isIncome';
        String? categoryId = catCache[cacheKey];

        if (categoryId == null) {
          // Tìm trong DB (có thể đã tạo ở vòng trước trong dry-run)
          final found = await catRepo.findByName(catName, isIncome: isIncome);
          if (found != null) {
            categoryId = found.id;
            catCache[cacheKey] = categoryId;
          } else {
            if (!dryRun) {
              // Tạo category mới với icon/color mặc định
              await catRepo.add(
                name: catName,
                colorHex: isIncome ? '#4CAF50' : '#FF5252',
                iconName: isIncome ? 'wallet' : 'shopping-cart',
                isIncome: isIncome,
              );
              final created =
              await catRepo.findByName(catName, isIncome: isIncome);
              categoryId = created!.id;
              catCache[cacheKey] = categoryId;
            } else {
              // Dry-run: dùng placeholder ID
              categoryId = 'preview_$cacheKey';
              catCache[cacheKey] = categoryId;
            }
            if (!newCategoryNames.contains(catName)) {
              newCategoryNames.add(catName);
            }
          }
        }

        // Check trùng lặp
        final fp = _fingerprint(
          createdAt: date,
          type: type,
          categoryId: categoryId,
          amount: amount,
          note: note,
        );

        // Trong dry-run, category_id là placeholder nên fingerprint sẽ khác.
        // Cần check bằng cách so sánh trực tiếp các trường (trừ category_id placeholder).
        bool isDuplicate = false;
        if (dryRun && categoryId.startsWith('preview_')) {
          // So sánh bằng fields khác (date + type + amount + note)
          isDuplicate = existingTxs.any((tx) =>
          tx.createdAt.millisecondsSinceEpoch ==
              date.millisecondsSinceEpoch &&
              tx.type == type &&
              tx.amount == amount &&
              (tx.note ?? '') == note);
        } else {
          isDuplicate = existingFingerprints.contains(fp);
        }

        if (isDuplicate) {
          skipped++;
        } else {
          added++;
          existingFingerprints.add(fp); // tránh dup trong cùng file
          if (!dryRun) {
            toInsert.add({
              'amount': amount,
              'type': type,
              'categoryId': categoryId,
              'note': note.isEmpty ? null : note,
              'createdAt': date,
            });
          }
        }
      } catch (e) {
        errors.add('Dòng $lineNum: lỗi không xác định — $e');
      }
    }

    // Batch insert
    if (!dryRun && toInsert.isNotEmpty) {
      await txRepo.batchAdd(toInsert);
    }

    return ImportResult(
      added: added,
      skipped: skipped,
      newCategories: newCategoryNames.length,
      newCategoryNames: newCategoryNames,
      errors: errors,
    );
  }

  /// Parse date string "d/M/yyyy HH:mm" → DateTime
  static DateTime? _parseDate(String s) {
    try {
      // Format: "28/4/2026 14:30"
      final parts = s.split(' ');
      if (parts.length != 2) return null;

      final dateParts = parts[0].split('/');
      if (dateParts.length != 3) return null;

      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);

      final timeParts = parts[1].split(':');
      if (timeParts.length != 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  /// Tạo fingerprint từ 5 trường để detect trùng lặp
  static String _fingerprint({
    required DateTime createdAt,
    required String type,
    required String categoryId,
    required int amount,
    required String note,
  }) {
    return '${createdAt.millisecondsSinceEpoch}|$type|$categoryId|$amount|$note';
  }
}
