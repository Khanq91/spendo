import '../../../core/db/powersync_db.dart';
import '../domain/detected_habit.dart';

class HabitRepository {
  /// Stream các habit chưa bị dismiss, sắp/đã đến chu kỳ
  Stream<List<DetectedHabit>> watchPending() {
    return db
        .watch(
          'SELECT * FROM detected_habits WHERE is_dismissed = 0 ORDER BY analyzed_at DESC',
        )
        .map((rows) => rows.map(DetectedHabit.fromMap).toList());
  }

  Future<void> dismiss(String id) async {
    await db.execute(
      'UPDATE detected_habits SET is_dismissed = 1 WHERE id = ?',
      [id],
    );
  }
}
