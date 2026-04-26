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