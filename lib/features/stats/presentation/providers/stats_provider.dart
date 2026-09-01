import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/period.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

/// Which side of the ledger the screen is breaking down.
///
/// The audit found Stats hard-wired to expense: the pie ignored income and the
/// bars drew only spending, so a month with nothing but a salary reported
/// "Chưa có dữ liệu". The toggle makes the side a choice.
enum StatsSide {
  expense,
  income;

  String get label => switch (this) {
    StatsSide.expense => 'Chi',
    StatsSide.income => 'Thu',
  };

  bool matches(Transaction t) => switch (this) {
    StatsSide.expense => t.isExpense,
    StatsSide.income => t.isIncome,
  };
}

/// The period Stats is showing.
final statsPeriodProvider = StateProvider<Period>(
  (_) => Period.month(DateTime(DateTime.now().year, DateTime.now().month)),
);

/// Expense or income — the side both charts break down.
final statsSideProvider = StateProvider<StatsSide>((_) => StatsSide.expense);

/// Every transaction inside the period.
final statsTransactionsProvider = StreamProvider.autoDispose<List<Transaction>>(
  (ref) {
    final period = ref.watch(statsPeriodProvider);
    final repo = ref.watch(transactionRepoProvider);
    return repo.watchByDateRange(period.start, period.end);
  },
);

/// One slice of the pie: a category and what it holds.
typedef StatsSlice = ({String categoryId, int amount, double share});

/// The chosen side, grouped by category and sorted largest first.
final statsByCategoryProvider = Provider.autoDispose<List<StatsSlice>>((ref) {
  final txs = ref.watch(statsTransactionsProvider).valueOrNull ?? const [];
  final side = ref.watch(statsSideProvider);

  final totals = <String, int>{};
  for (final t in txs.where(side.matches)) {
    totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
  }

  final total = totals.values.fold(0, (sum, value) => sum + value);
  final slices = [
    for (final entry in totals.entries)
      (
        categoryId: entry.key,
        amount: entry.value,
        share: total > 0 ? entry.value / total : 0.0,
      ),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  return slices;
});

/// The chosen side's total across the period.
final statsSideTotalProvider = Provider.autoDispose<int>((ref) {
  final txs = ref.watch(statsTransactionsProvider).valueOrNull ?? const [];
  final side = ref.watch(statsSideProvider);
  return txs.where(side.matches).fold(0, (sum, t) => sum + t.amount);
});

/// Per-day totals, keyed by date so a period spanning months still lines up.
final statsDailyTotalsProvider =
    Provider.autoDispose<Map<DateTime, ({int income, int expense})>>((ref) {
      final txs = ref.watch(statsTransactionsProvider).valueOrNull ?? const [];
      final map = <DateTime, ({int income, int expense})>{};
      for (final t in txs) {
        final day = DateTime(
          t.createdAt.year,
          t.createdAt.month,
          t.createdAt.day,
        );
        final current = map[day] ?? (income: 0, expense: 0);
        map[day] = t.isExpense
            ? (income: current.income, expense: current.expense + t.amount)
            : (income: current.income + t.amount, expense: current.expense);
      }
      return map;
    });

/// Income, expense and the balance between them, for the header.
final statsSummaryProvider =
    Provider.autoDispose<({int income, int expense, int balance})>((ref) {
      final txs = ref.watch(statsTransactionsProvider).valueOrNull ?? const [];
      final income = txs.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
      final expense = txs
          .where((t) => t.isExpense)
          .fold(0, (s, t) => s + t.amount);
      return (income: income, expense: expense, balance: income - expense);
    });
