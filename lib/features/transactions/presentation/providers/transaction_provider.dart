import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/transaction_repository.dart';
import '../../domain/transaction.dart';

final transactionRepoProvider = Provider((_) => TransactionRepository());

final selectedMonthProvider = StateProvider<DateTime>(
      (_) => DateTime(DateTime.now().year, DateTime.now().month),
);

final transactionsProvider = StreamProvider.autoDispose<List<Transaction>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepoProvider);
  return repo.watchByMonth(month.year, month.month);
});

/// Tổng thu, tổng chi, số dư theo tháng đang chọn
final summaryProvider = Provider.autoDispose<({int income, int expense, int balance})>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  final income = txs.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  final expense = txs.where((t) => t.isExpense).fold(0, (s, t) => s + t.amount);
  return (income: income, expense: expense, balance: income - expense);
});

// ── Filter state ─────────────────────────────────────────────────────────────

final selectedCategoryFilterProvider = StateProvider<String?>((_) => null);
final searchQueryProvider = StateProvider<String>((_) => '');

/// Filtered list — derived từ transactionsProvider, áp filter + search
final filteredTransactionsProvider = Provider.autoDispose<List<Transaction>>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  return txs.where((t) {
    final matchCat = categoryId == null || t.categoryId == categoryId;
    final matchQuery = query.isEmpty ||
        t.note?.toLowerCase().contains(query) == true ||
        t.amount.toString().contains(query);
    return matchCat && matchQuery;
  }).toList();
});

// Stats: group theo category
final expensesByCategoryProvider = Provider.autoDispose<Map<String, int>>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  final map = <String, int>{};
  for (final t in txs.where((t) => t.isExpense)) {
    map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
  }
  return map;
});

// Stats: group theo ngày trong tháng
final dailyTotalsProvider = Provider.autoDispose<Map<int, ({int income, int expense})>>((ref) {
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