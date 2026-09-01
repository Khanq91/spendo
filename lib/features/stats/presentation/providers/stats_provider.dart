import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/period.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

// ── Date range model ─────────────────────────────────────────────────────────

// The range model moved to `shared/domain/period.dart` when the two time
// pickers were merged (screen 24): Stats, Giao dịch, Home and Hạn mức all ask
// the same question. The Stats screen keeps its own names below.

/// Alias kept so the Stats screen — redesigned in phase 5 — still compiles.
typedef StatsDateRange = Period;

// ── Providers ────────────────────────────────────────────────────────────────

/// Khoảng thời gian đang xem trong Stats. Mặc định = tháng hiện tại.
final statsDateRangeProvider = StateProvider<Period>(
  (_) => Period.month(DateTime(DateTime.now().year, DateTime.now().month)),
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
