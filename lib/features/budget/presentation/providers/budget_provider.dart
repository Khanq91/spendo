import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/budget_repository.dart';
import '../../domain/budget.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

final budgetRepoProvider = Provider((ref) => BudgetRepository());

final currentBudgetProvider = StreamProvider.autoDispose<Budget?>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final key = Budget.monthKey(month);
  return ref.watch(budgetRepoProvider).watchMonth(key);
});

// Phần trăm đã dùng so với budget
final budgetProgressProvider = Provider.autoDispose<({
int budget,
int spent,
double percent,
bool isOver,
})?>((ref) {
  final budget = ref.watch(currentBudgetProvider).valueOrNull;
  if (budget == null) return null;

  final summary = ref.watch(summaryProvider);
  final percent = budget.amount > 0
      ? summary.expense / budget.amount
      : 0.0;

  return (
  budget: budget.amount,
  spent: summary.expense,
  percent: percent,
  isOver: summary.expense > budget.amount,
  );
});