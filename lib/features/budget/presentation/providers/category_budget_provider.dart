import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../data/category_budget_repository.dart';
import '../../domain/category_budget.dart';

final categoryBudgetRepoProvider =
Provider((_) => CategoryBudgetRepository());

/// Stream toàn bộ category budgets
final categoryBudgetsProvider = StreamProvider<List<CategoryBudget>>((ref) {
  return ref.watch(categoryBudgetRepoProvider).watchAll();
});

/// Map category_id → CategoryBudget để lookup O(1)
final categoryBudgetMapProvider =
Provider.autoDispose<Map<String, CategoryBudget>>((ref) {
  final budgets = ref.watch(categoryBudgetsProvider).valueOrNull ?? [];
  return {for (final b in budgets) b.categoryId: b};
});

/// Progress mỗi danh mục có budget:
///   category_id → {budget, spent, percent, isOver}
final categoryBudgetProgressProvider = Provider.autoDispose<
    Map<
        String,
        ({
        int budget,
        int spent,
        double percent,
        bool isOver,
        })>>((ref) {
  final budgetMap = ref.watch(categoryBudgetMapProvider);
  final spentMap = ref.watch(expensesByCategoryProvider); // đã có sẵn

  final result = <String,
      ({int budget, int spent, double percent, bool isOver})>{};

  for (final entry in budgetMap.entries) {
    final categoryId = entry.key;
    final budget = entry.value.amount;
    final spent = spentMap[categoryId] ?? 0;
    final percent = budget > 0 ? spent / budget : 0.0;
    result[categoryId] = (
    budget: budget,
    spent: spent,
    percent: percent,
    isOver: spent > budget,
    );
  }

  return result;
});

/// Danh sách danh mục gần/đã vượt hạn mức (percent >= 0.7) — dùng cho BudgetCard expand
final nearLimitCategoriesProvider = Provider.autoDispose<
    List<({String categoryId, int budget, int spent, double percent, bool isOver})>>(
      (ref) {
    final progress = ref.watch(categoryBudgetProgressProvider);
    final allCats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catMap = {for (final c in allCats) c.id: c};

    return progress.entries
        .where((e) => e.value.percent >= 0.7)
        .map((e) => (
    categoryId: e.key,
    budget: e.value.budget,
    spent: e.value.spent,
    percent: e.value.percent,
    isOver: e.value.isOver,
    ))
        .where((e) => catMap.containsKey(e.categoryId)) // chỉ giữ cat còn tồn tại
        .toList()
      ..sort((a, b) => b.percent.compareTo(a.percent)); // sort giảm dần
  },
);