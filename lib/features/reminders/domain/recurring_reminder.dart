enum ReminderFrequency { daily, weekly, monthly }

extension ReminderFrequencyLabel on ReminderFrequency {
  String get frequencyLabel => switch (this) {
    ReminderFrequency.daily => 'Hàng ngày',
    ReminderFrequency.weekly => 'Hàng tuần',
    ReminderFrequency.monthly => 'Hàng tháng',
  };
}

class RecurringReminder {
  final String id;
  final String title;
  final String categoryId;
  final int? amountHint;
  final ReminderFrequency frequency;
  final int? dayOfWeek;   // 1=Mon..7=Sun, weekly only
  final int? dayOfMonth;  // 1-31, monthly only
  final int hour;
  final int minute;
  final bool isActive;
  final DateTime nextTrigger;

  const RecurringReminder({
    required this.id,
    required this.title,
    required this.categoryId,
    this.amountHint,
    required this.frequency,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.hour,
    required this.minute,
    required this.isActive,
    required this.nextTrigger,
  });

  factory RecurringReminder.fromMap(Map<String, dynamic> map) {
    return RecurringReminder(
      id: map['id'] as String,
      title: map['title'] as String,
      categoryId: map['category_id'] as String,
      amountHint: map['amount_hint'] != null
          ? int.tryParse(map['amount_hint'] as String)
          : null,
      frequency: ReminderFrequency.values.firstWhere(
            (f) => f.name == map['frequency'],
        orElse: () => ReminderFrequency.monthly,
      ),
      dayOfWeek: map['day_of_week'] as int?,
      dayOfMonth: map['day_of_month'] as int?,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      isActive: (map['is_active'] as int) == 1,
      nextTrigger: DateTime.parse(map['next_trigger'] as String),
    );
  }

  String get frequencyLabel {
    return switch (frequency) {
      ReminderFrequency.daily => 'Hàng ngày',
      ReminderFrequency.weekly => 'Hàng tuần',
      ReminderFrequency.monthly => 'Hàng tháng',
    };
  }

  String get scheduleDetail {
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return switch (frequency) {
      ReminderFrequency.daily => 'Mỗi ngày lúc $timeStr',
      ReminderFrequency.weekly =>
      'Mỗi ${_weekdayName(dayOfWeek ?? 1)} lúc $timeStr',
      ReminderFrequency.monthly =>
      'Ngày ${dayOfMonth ?? 1} hàng tháng lúc $timeStr',
    };
  }

  static String _weekdayName(int day) {
    const names = ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    return names[day.clamp(1, 7)];
  }

  /// Tính nextTrigger kế tiếp từ thời điểm hiện tại
  static DateTime calcNextTrigger({
    required ReminderFrequency frequency,
    required int hour,
    required int minute,
    int? dayOfWeek,
    int? dayOfMonth,
  }) {
    final now = DateTime.now();
    switch (frequency) {
      case ReminderFrequency.daily:
        var t = DateTime(now.year, now.month, now.day, hour, minute);
        if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
        return t;
      case ReminderFrequency.weekly:
        final targetDow = dayOfWeek ?? 1; // 1=Mon
        var t = DateTime(now.year, now.month, now.day, hour, minute);
        // Dart weekday: 1=Mon..7=Sun — matches our scheme
        final diff = (targetDow - now.weekday + 7) % 7;
        t = t.add(Duration(days: diff));
        if (!t.isAfter(now)) t = t.add(const Duration(days: 7));
        return t;
      case ReminderFrequency.monthly:
        final dom = (dayOfMonth ?? 1).clamp(1, 28); // clamp to 28 to be safe
        var t = DateTime(now.year, now.month, dom, hour, minute);
        if (!t.isAfter(now)) {
          t = DateTime(now.year, now.month + 1, dom, hour, minute);
        }
        return t;
    }
  }
}

// Preset templates
class ReminderPreset {
  final String title;
  final String iconName; // maps to category icon
  final int? suggestedAmount;
  final ReminderFrequency frequency;

  const ReminderPreset({
    required this.title,
    required this.iconName,
    this.suggestedAmount,
    required this.frequency,
  });
}

const kReminderPresets = [
  ReminderPreset(title: 'Dầu gội', iconName: 'favorite', suggestedAmount: 50000, frequency: ReminderFrequency.monthly),
  ReminderPreset(title: 'Tiền điện', iconName: 'home', suggestedAmount: 300000, frequency: ReminderFrequency.monthly),
  ReminderPreset(title: 'Tiền nước', iconName: 'home', suggestedAmount: 100000, frequency: ReminderFrequency.monthly),
  ReminderPreset(title: 'Xăng xe', iconName: 'directions_car', suggestedAmount: 100000, frequency: ReminderFrequency.weekly),
  ReminderPreset(title: 'Đồ ăn vặt', iconName: 'restaurant', suggestedAmount: 50000, frequency: ReminderFrequency.weekly),
  ReminderPreset(title: 'Tiền thuê nhà', iconName: 'home', suggestedAmount: 3000000, frequency: ReminderFrequency.monthly),
];