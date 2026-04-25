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

/// Tính tổng thu, tổng chi, số dư từ list hiện tại
final summaryProvider = Provider.autoDispose<({int income, int expense, int balance})>((ref) {
  final txs = ref.watch(transactionsProvider).valueOrNull ?? [];
  final income = txs.where((t) => t.isIncome).fold(0, (s, t) => s + t.amount);
  final expense = txs.where((t) => t.isExpense).fold(0, (s, t) => s + t.amount);
  return (income: income, expense: expense, balance: income - expense);
});