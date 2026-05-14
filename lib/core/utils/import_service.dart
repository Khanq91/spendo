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

    String content = await file.readAsString();
    if (content.startsWith('\uFEFF')) content = content.substring(1);

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

    final catRepo = CategoryRepository();
    final txRepo = TransactionRepository();
    final existingCats = await catRepo.getAll();
    final existingTxs = await txRepo.getAll();

    // Build fingerprint set — normalize timestamp đến phút để khớp với CSV export
    final existingFingerprints = <String>{};
    for (final tx in existingTxs) {
      existingFingerprints.add(_fingerprint(
        createdAt: _truncateToMinute(tx.createdAt),
        type: tx.type,
        categoryId: tx.categoryId,
        amount: tx.amount,
        note: tx.note ?? '',
      ));
    }

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
      final lineNum = i + 2;

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

        final date = _parseDate(dateStr);
        if (date == null) {
          errors.add('Dòng $lineNum: không parse được ngày "$dateStr"');
          continue;
        }

        final String type;
        if (typeStr == 'Chi') {
          type = 'expense';
        } else if (typeStr == 'Thu') {
          type = 'income';
        } else {
          errors.add('Dòng $lineNum: loại "$typeStr" không hợp lệ (cần Chi/Thu)');
          continue;
        }

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

        final isIncome = type == 'income';
        final cacheKey = '$catName|$isIncome';
        String? categoryId = catCache[cacheKey];

        if (categoryId == null) {
          final found = await catRepo.findByName(catName, isIncome: isIncome);
          if (found != null) {
            categoryId = found.id;
            catCache[cacheKey] = categoryId;
          } else {
            if (!dryRun) {
              await catRepo.add(
                name: catName,
                colorHex: isIncome ? '#4CAF50' : '#FF5252',
                iconName: isIncome ? 'work' : 'more_horiz',
                isIncome: isIncome,
              );
              final created = await catRepo.findByName(catName, isIncome: isIncome);
              categoryId = created!.id;
              catCache[cacheKey] = categoryId;
            } else {
              categoryId = 'preview_$cacheKey';
              catCache[cacheKey] = categoryId;
            }
            if (!newCategoryNames.contains(catName)) {
              newCategoryNames.add(catName);
            }
          }
        }

        // Fingerprint dùng timestamp đã truncate đến phút — khớp với export format
        final fp = _fingerprint(
          createdAt: date, // date từ CSV đã là đến phút (seconds=0)
          type: type,
          // Dry-run với preview category: so sánh không dùng categoryId
          categoryId: categoryId.startsWith('preview_') ? '' : categoryId,
          amount: amount,
          note: note,
        );

        bool isDuplicate;
        if (categoryId.startsWith('preview_')) {
          // Dry-run, category mới: so sánh theo date+type+amount+note (bỏ qua categoryId)
          isDuplicate = existingFingerprints.any((existing) {
            final parts = existing.split('|');
            if (parts.length < 5) return false;
            final exFp = _fingerprint(
              createdAt: DateTime.fromMillisecondsSinceEpoch(int.tryParse(parts[0]) ?? 0),
              type: parts[1],
              categoryId: '',
              amount: int.tryParse(parts[3]) ?? -1,
              note: parts.sublist(4).join('|'),
            );
            return exFp == fp;
          });
        } else {
          isDuplicate = existingFingerprints.contains(fp);
        }

        if (isDuplicate) {
          skipped++;
        } else {
          added++;
          existingFingerprints.add(fp);
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

  /// Truncate DateTime đến phút (seconds và milliseconds = 0)
  /// CSV export chỉ lưu đến HH:mm nên cần normalize để so sánh đúng
  static DateTime _truncateToMinute(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  static DateTime? _parseDate(String s) {
    try {
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