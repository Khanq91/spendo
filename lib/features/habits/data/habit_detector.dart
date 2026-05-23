import 'dart:math';
import '../../../core/db/powersync_db.dart';

/// Phân tích lịch sử giao dịch để tìm các thói quen mua lặp lại.
/// Kết quả được upsert vào bảng detected_habits.
class HabitDetector {
  // Số lần xuất hiện tối thiểu để coi là thói quen
  static const int _minOccurrences = 3;
  // Gap tối thiểu (ngày) để không suggest thứ mua hàng ngày như cà phê
  static const int _minGapDays = 3;
  // Hệ số độ lệch chuẩn chấp nhận được (< 60% median là đủ đều)
  static const double _maxCvThreshold = 0.6;

  /// Chạy full analysis. Gọi khi user mở RemindersScreen.
  static Future<void> analyze() async {
    // 1. Lấy tất cả expense transactions có note không rỗng
    final rows = await db.getAll(
      "SELECT note, category_id, created_at FROM transactions "
      "WHERE type = 'expense' AND note IS NOT NULL AND note != '' "
      "ORDER BY created_at ASC",
    );

    if (rows.isEmpty) return;

    // 2. Group by normalized keyword
    final Map<String, List<_Entry>> groups = {};
    for (final row in rows) {
      final keyword = _normalize(row['note'] as String);
      if (keyword.isEmpty) continue;
      final catId = row['category_id'] as String;
      final ts = int.parse(row['created_at'] as String);
      final date = DateTime.fromMillisecondsSinceEpoch(ts);
      groups.putIfAbsent(keyword, () => []).add(_Entry(catId, date));
    }

    // 3. Analyze từng group
    for (final entry in groups.entries) {
      final keyword = entry.key;
      final occurrences = entry.value;

      if (occurrences.length < _minOccurrences) continue;

      // Lấy category_id xuất hiện nhiều nhất trong group này
      final dominantCatId = _dominantCategory(occurrences);

      // Tính gaps giữa các lần mua
      final dates =
          occurrences.map((e) => e.date).toList()
            ..sort((a, b) => a.compareTo(b));

      final gaps = <int>[];
      for (int i = 1; i < dates.length; i++) {
        gaps.add(dates[i].difference(dates[i - 1]).inDays);
      }

      final median = _median(gaps);
      if (median < _minGapDays) continue;

      final cv = _coefficientOfVariation(gaps);
      if (cv > _maxCvThreshold) continue;

      final lastOccurrence = dates.last;

      // 4. Upsert vào detected_habits
      await _upsert(
        keyword: keyword,
        categoryId: dominantCatId,
        medianGapDays: median,
        lastOccurrence: lastOccurrence,
        occurrenceCount: occurrences.length,
      );
    }
  }

  static String _normalize(String note) {
    return note.toLowerCase().trim();
  }

  static String _dominantCategory(List<_Entry> entries) {
    final counts = <String, int>{};
    for (final e in entries) {
      counts[e.categoryId] = (counts[e.categoryId] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static int _median(List<int> values) {
    final sorted = List<int>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return ((sorted[mid - 1] + sorted[mid]) / 2).round();
  }

  static double _coefficientOfVariation(List<int> values) {
    if (values.length < 2) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return 0.0;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance) / mean;
  }

  static Future<void> _upsert({
    required String keyword,
    required String categoryId,
    required int medianGapDays,
    required DateTime lastOccurrence,
    required int occurrenceCount,
  }) async {
    final existing = await db.getOptional(
      'SELECT id, is_dismissed FROM detected_habits WHERE keyword = ?',
      [keyword],
    );

    final now = DateTime.now().toIso8601String();

    if (existing != null) {
      // Cập nhật stats nhưng giữ nguyên is_dismissed
      await db.execute(
        '''UPDATE detected_habits SET
            category_id = ?,
            median_gap_days = ?,
            last_occurrence = ?,
            occurrence_count = ?,
            analyzed_at = ?
           WHERE keyword = ?''',
        [
          categoryId,
          medianGapDays,
          lastOccurrence.toIso8601String(),
          occurrenceCount,
          now,
          keyword,
        ],
      );
    } else {
      await db.execute(
        '''INSERT INTO detected_habits(
            id, keyword, category_id, median_gap_days,
            last_occurrence, occurrence_count, is_dismissed, analyzed_at
           ) VALUES(uuid(), ?, ?, ?, ?, ?, 0, ?)''',
        [
          keyword,
          categoryId,
          medianGapDays,
          lastOccurrence.toIso8601String(),
          occurrenceCount,
          now,
        ],
      );
    }
  }
}

class _Entry {
  final String categoryId;
  final DateTime date;
  const _Entry(this.categoryId, this.date);
}
