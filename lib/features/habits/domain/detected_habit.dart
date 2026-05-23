class DetectedHabit {
  final String id;
  final String keyword;
  final String categoryId;
  final int medianGapDays;
  final DateTime lastOccurrence;
  final int occurrenceCount;
  final bool isDismissed;
  final DateTime analyzedAt;

  const DetectedHabit({
    required this.id,
    required this.keyword,
    required this.categoryId,
    required this.medianGapDays,
    required this.lastOccurrence,
    required this.occurrenceCount,
    required this.isDismissed,
    required this.analyzedAt,
  });

  /// Số ngày kể từ lần mua cuối
  int get daysSinceLast => DateTime.now().difference(lastOccurrence).inDays;

  /// True nếu đã đến hoặc gần đến chu kỳ (>= 80% gap)
  bool get isDue => daysSinceLast >= (medianGapDays * 0.8).floor();

  factory DetectedHabit.fromMap(Map<String, dynamic> map) {
    return DetectedHabit(
      id: map['id'] as String,
      keyword: map['keyword'] as String,
      categoryId: map['category_id'] as String,
      medianGapDays: map['median_gap_days'] as int,
      lastOccurrence: DateTime.parse(map['last_occurrence'] as String),
      occurrenceCount: map['occurrence_count'] as int,
      isDismissed: (map['is_dismissed'] as int) == 1,
      analyzedAt: DateTime.parse(map['analyzed_at'] as String),
    );
  }
}
