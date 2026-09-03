import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/transactions/data/transaction_repository.dart';

enum ExportRange { thisMonth, threeMonths, all }

/// A wallet name as a file-name fragment: "Ví tiền mặt" → `vi_tien_mat`.
///
/// Vietnamese letters lose their marks, everything else non-alphanumeric
/// collapses to one underscore, and the result is capped at 24 characters so
/// the file name stays readable on every share target.
String fileSlug(String name) {
  final buffer = StringBuffer();
  for (final rune in name.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final marked = _markedLetters.indexOf(char);
    buffer.write(marked < 0 ? char : _baseLetters[marked]);
  }
  final ascii = buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  if (ascii.isEmpty) return 'vi';
  return ascii.length > 24 ? ascii.substring(0, 24) : ascii;
}

/// Every lower-case Vietnamese letter with a mark, and the base letter at the
/// same index in [_baseLetters].
const _markedLetters =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _baseLetters =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

class ExportService {
  /// Writes the transactions in [range] to a CSV file and hands it to the
  /// share sheet. With [walletId] only that wallet's rows go out, and the
  /// file is named after it — the wallet page offers this from its menu.
  static Future<void> exportCSV(
    ExportRange range, {
    String? walletId,
    String? walletName,
  }) async {
    final now = DateTime.now();

    DateTime? from;
    switch (range) {
      case ExportRange.thisMonth:
        from = DateTime(now.year, now.month);
      case ExportRange.threeMonths:
        from = DateTime(now.year, now.month - 2);
      case ExportRange.all:
        from = null;
    }

    // lấy transactions
    final txs = await TransactionRepository().getRange(
      from: from,
      walletId: walletId,
    );

    // lấy categories để map tên
    final cats = await CategoryRepository().getByType(isIncome: false) +
        await CategoryRepository().getByType(isIncome: true);
    final catMap = {for (final c in cats) c.id: c.name};

    // build CSV rows
    final rows = <List<dynamic>>[
      ['Ngày', 'Loại', 'Danh mục', 'Số tiền', 'Ghi chú'],
      ...txs.map((t) => [
        '${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year} '
            '${t.createdAt.hour.toString().padLeft(2, '0')}:'
            '${t.createdAt.minute.toString().padLeft(2, '0')}',
        t.isExpense ? 'Chi' : 'Thu',
        catMap[t.categoryId] ?? 'Không rõ',
        t.amount,
        t.note ?? '',
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);

    // lưu file tạm
    final dir = await getTemporaryDirectory();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final scope = walletName == null ? '' : '_${fileSlug(walletName)}';
    final fileName = 'spendo${scope}_$stamp.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    // share
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Spendo — Dữ liệu thu chi',
    );
  }
}