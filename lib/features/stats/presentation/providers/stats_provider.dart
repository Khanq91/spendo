import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../../transactions/domain/transaction.dart';

// ── Date range model ─────────────────────────────────────────────────────────

enum StatsTimeMode { month, custom }

class StatsDateRange {
  final StatsTimeMode mode;
  final DateTime start;
  final DateTime end;

  const StatsDateRange({
    required this.mode,
    required this.start,
    required this.end,
  });

  /// Từ 1 tháng cụ thể (tương thích hành vi cũ)
  factory StatsDateRange.fromMonth(DateTime month) {
    return StatsDateRange(
      mode: StatsTimeMode.month,
      start: DateTime(month.year, month.month),
      end: DateTime(month.year, month.month + 1),
    );
  }

  /// Custom range: start & end đều inclusive
  factory StatsDateRange.custom(DateTime start, DateTime end) {
    return StatsDateRange(
      mode: StatsTimeMode.custom,
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day + 1), // inclusive end
    );
  }

  int get daySpan => end.difference(start).inDays;

  /// Label ngắn gọn hiển thị trên AppBar
  String get label {
    if (mode == StatsTimeMode.month) {
      return 'Tháng ${start.month}/${start.year}';
    }
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    // end đã bị +1 ngày, nên hiển thị end-1
    final displayEnd = end.subtract(const Duration(days: 1));
    if (start.year == displayEnd.year) {
      return '${fmt(start)} – ${fmt(displayEnd)}/${displayEnd.year}';
    }
    return '${fmt(start)}/${start.year} – ${fmt(displayEnd)}/${displayEnd.year}';
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

/// Khoảng thời gian đang xem trong Stats. Mặc định = tháng hiện tại.
final statsDateRangeProvider = StateProvider<StatsDateRange>(
  (_) => StatsDateRange.fromMonth(
    DateTime(DateTime.now().year, DateTime.now().month),
  ),
);

/// Stream transactions theo khoảng thời gian Stats đang chọn
final statsTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
  final range = ref.watch(statsDateRangeProvider);
  final repo = ref.watch(transactionRepoProvider);
  return repo.watchByDateRange(range.start, range.end);
});

/// Group chi tiêu theo category (pie chart)
final statsExpensesByCategoryProvider =
    Provider.autoDispose<Map<String, int>>((ref) {
  final txs = ref.watch(statsTransactionsProvider).valueOrNull ?? [];
  final map = <String, int>{};
  for (final t in txs.where((t) => t.isExpense)) {
    map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
  }
  return map;
});

/// Group theo ngày (bar chart) — dùng DateTime key để hỗ trợ cross-month
final statsDailyTotalsProvider =
    Provider.autoDispose<Map<DateTime, ({int income, int expense})>>((ref) {
  final txs = ref.watch(statsTransactionsProvider).valueOrNull ?? [];
  final map = <DateTime, ({int income, int expense})>{};
  for (final t in txs) {
    final dateKey =
        DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
    final cur = map[dateKey] ?? (income: 0, expense: 0);
    map[dateKey] = t.isExpense
        ? (income: cur.income, expense: cur.expense + t.amount)
        : (income: cur.income + t.amount, expense: cur.expense);
  }
  return map;
});

/// Tổng thu chi cho Stats
final statsSummaryProvider =
    Provider.autoDispose<({int income, int expense, int balance})>((ref) {
  final txs = ref.watch(statsTransactionsProvider).valueOrNull ?? [];
  final income =
      txs.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  final expense =
      txs.where((t) => t.isExpense).fold(0, (s, t) => s + t.amount);
  return (income: income, expense: expense, balance: income - expense);
});
