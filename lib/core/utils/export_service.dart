import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/transactions/data/transaction_repository.dart';

enum ExportRange { thisMonth, threeMonths, all }

class ExportService {
  static Future<void> exportCSV(ExportRange range) async {
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
    final txs = await TransactionRepository().getRange(from: from);

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
    final fileName =
        'spendo_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csv);

    // share
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Spendo — Dữ liệu thu chi',
    );
  }
}