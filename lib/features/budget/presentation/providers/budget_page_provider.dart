import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/period.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../domain/budget.dart';
import 'budget_provider.dart';
import 'category_budget_provider.dart';

/// The month the `/budget` page is showing.
///
/// Budgets are stored per month, so the page is month-at-a-time and its picker
/// hides the multi-month spans. It starts on Home's month and then follows its
/// own stepper — the audit found the old sheets silently writing to whatever
/// month Home happened to be on, with only a 12px subtitle saying so.
final budgetPeriodProvider = StateProvider<Period>((ref) {
  return Period.month(ref.watch(selectedMonthProvider));
});

/// The month budget for [budgetPeriodProvider], not for Home's month.
final budgetPageBudgetProvider = StreamProvider.autoDispose<Budget?>((ref) {
  final period = ref.watch(budgetPeriodProvider);
  return ref.watch(budgetRepoProvider).watchMonth(Budget.monthKey(period.start));
});

/// Every transaction inside the page's month.
final budgetPeriodTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
      final period = ref.watch(budgetPeriodProvider);
      return TransactionRepository().watchByDateRange(period.start, period.end);
    });

/// Expense per category inside the page's month.
final budgetSpentByCategoryProvider = Provider.autoDispose<Map<String, int>>((
  ref,
) {
  final txs =
      ref.watch(budgetPeriodTransactionsProvider).valueOrNull ?? const [];
  final map = <String, int>{};
  for (final tx in txs.where((t) => t.isExpense)) {
    map[tx.categoryId] = (map[tx.categoryId] ?? 0) + tx.amount;
  }
  return map;
});

/// Total expense inside the page's month.
final budgetSpentTotalProvider = Provider.autoDispose<int>((ref) {
  final txs =
      ref.watch(budgetPeriodTransactionsProvider).valueOrNull ?? const [];
  return txs.where((t) => t.isExpense).fold(0, (sum, t) => sum + t.amount);
});

/// How each category with a limit is tracking inside the page's month.
final budgetPageCategoryProgressProvider = Provider.autoDispose<
    Map<String, ({int budget, int spent, double percent, bool isOver})>>((ref) {
  final budgets = ref.watch(categoryBudgetMapProvider);
  final spentMap = ref.watch(budgetSpentByCategoryProvider);

  return {
    for (final entry in budgets.entries)
      entry.key: (
        budget: entry.value.amount,
        spent: spentMap[entry.key] ?? 0,
        percent: entry.value.amount > 0
            ? (spentMap[entry.key] ?? 0) / entry.value.amount
            : 0.0,
        isOver: (spentMap[entry.key] ?? 0) > entry.value.amount,
      ),
  };
});
