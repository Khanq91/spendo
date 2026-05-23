import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/habit_detector.dart';
import '../../data/habit_repository.dart';
import '../../domain/detected_habit.dart';

final habitRepoProvider = Provider((_) => HabitRepository());

final detectedHabitsProvider = StreamProvider<List<DetectedHabit>>((ref) {
  return ref.watch(habitRepoProvider).watchPending();
});
final pendingHabitSuggestionsProvider =
    Provider.autoDispose<List<DetectedHabit>>((ref) {
      final all = ref.watch(detectedHabitsProvider).valueOrNull ?? [];
      return all.where((h) => h.isDue).toList();
    });

/// Chạy analysis — gọi một lần khi mở RemindersScreen
final habitAnalysisProvider = FutureProvider.autoDispose<void>((ref) async {
  await HabitDetector.analyze();
});
