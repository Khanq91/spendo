import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/period.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_filter.dart';

final transactionRepoProvider = Provider((_) => TransactionRepository());

/// The month Home is showing. Home is month-at-a-time by design; the screens
/// that accept any span watch [transactionsPeriodProvider] instead.
final selectedMonthProvider = StateProvider<DateTime>(
  (_) => DateTime(DateTime.now().year, DateTime.now().month),
);

/// The period the transaction list is showing.
///
/// Starts on the month Home is showing, then follows its own picker — the two
/// screens answer different questions, and the audit found the shared global
/// meant a filter set on one silently applied to the other.
final transactionsPeriodProvider = StateProvider<Period>((ref) {
  return Period.month(ref.watch(selectedMonthProvider));
});

/// Home's transactions — always the selected month.
final transactionsProvider = StreamProvider.autoDispose<List<Transaction>>((
  ref,
) {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepoProvider);
  return repo.watchByMonth(month.year, month.month);
});

/// Tổng thu, tổng chi, số dư theo tháng đang chọn
final summaryProvider =
    Provider.autoDispose<({int income, int expense, int balance})>((ref) {
      final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
      final totals = summarise(txs);
      return (
        income: totals.income,
        expense: totals.expense,
        balance: totals.income - totals.expense,
      );
    });

// ── Transaction list screen ──────────────────────────────────────────────────

/// Everything narrowing the transaction list.
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (_) => const TransactionFilter(),
);

/// Raw transactions for the list screen's period.
final periodTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
      final period = ref.watch(transactionsPeriodProvider);
      final repo = ref.watch(transactionRepoProvider);
      return repo.watchByDateRange(period.start, period.end);
    });

/// The list screen's transactions, with the filter applied.
final filteredTransactionsProvider = Provider.autoDispose<List<Transaction>>((
  ref,
) {
  final txs = ref.watch(periodTransactionsProvider).valueOrNull ?? [];
  return ref.watch(transactionFilterProvider).apply(txs);
});

// ── Stats grouping (month-scoped) ────────────────────────────────────────────

// Stats: group theo category
final expensesByCategoryProvider = Provider.autoDispose<Map<String, int>>((
  ref,
) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  final map = <String, int>{};
  for (final t in txs.where((t) => t.isExpense)) {
    map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
  }
  return map;
});

// Stats: group theo ngày trong tháng
final dailyTotalsProvider =
    Provider.autoDispose<Map<int, ({int income, int expense})>>((ref) {
      final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
      final map = <int, ({int income, int expense})>{};
      for (final t in txs) {
        final day = t.createdAt.day;
        final cur = map[day] ?? (income: 0, expense: 0);
        map[day] = t.isExpense
            ? (income: cur.income, expense: cur.expense + t.amount)
            : (income: cur.income + t.amount, expense: cur.expense);
      }
      return map;
    });
