import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/category.dart';
import '../../data/category_repository.dart';

final categoryRepoProvider = Provider((_) => CategoryRepository());

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepoProvider).watchAll();
});

final expenseCategoriesProvider = Provider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesProvider).valueOrNull?.where((c) => !c.isIncome).toList() ?? [];
});

final incomeCategoriesProvider = Provider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesProvider).valueOrNull?.where((c) => c.isIncome).toList() ?? [];
});

/// How many transactions each category holds, keyed by category id.
///
/// The Danh mục page shows it on every row so "không xoá được" is visible
/// before the tap, not only in the error that follows it.
final categoryTransactionCountsProvider = StreamProvider<Map<String, int>>((
  ref,
) {
  return ref.watch(categoryRepoProvider).watchTransactionCounts();
});