import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/reminders/domain/recurring_reminder.dart';

// A Thursday morning.
final _now = DateTime(2026, 9, 3, 10);

RecurringReminder _reminder({
  ReminderFrequency frequency = ReminderFrequency.monthly,
  int? dayOfWeek,
  int? dayOfMonth = 5,
  int hour = 20,
  int warnBeforeHours = 0,
  required DateTime nextTrigger,
}) => RecurringReminder(
  id: 'r1',
  title: 'Tiền điện',
  categoryId: 'bills',
  frequency: frequency,
  dayOfWeek: dayOfWeek,
  dayOfMonth: dayOfMonth,
  hour: hour,
  minute: 0,
  isActive: true,
  nextTrigger: nextTrigger,
  warnBeforeHours: warnBeforeHours,
);

void main() {
  group('calcNextTrigger', () {
    test('daily: today at the time while it is ahead, else tomorrow', () {
      expect(
        RecurringReminder.calcNextTrigger(
          frequency: ReminderFrequency.daily,
          hour: 20,
          minute: 0,
          now: _now,
        ),
        DateTime(2026, 9, 3, 20),
      );
      expect(
        RecurringReminder.calcNextTrigger(
          frequency: ReminderFrequency.daily,
          hour: 8,
          minute: 0,
          now: _now,
        ),
        DateTime(2026, 9, 4, 8),
      );
    });

    test('weekly: the requested weekday, this week if still ahead', () {
      expect(
        RecurringReminder.calcNextTrigger(
          frequency: ReminderFrequency.weekly,
          hour: 20,
          minute: 0,
          dayOfWeek: DateTime.monday,
          now: _now,
        ),
        DateTime(2026, 9, 7, 20),
      );
      // Same weekday as today: later today, or a week on once it has passed.
      expect(
        RecurringReminder.calcNextTrigger(
          frequency: ReminderFrequency.weekly,
          hour: 20,
          minute: 0,
          dayOfWeek: DateTime.thursday,
          now: _now,
        ),
        DateTime(2026, 9, 3, 20),
      );
      expect(
        RecurringReminder.calcNextTrigger(
          frequency: ReminderFrequency.weekly,
          hour: 8,
          minute: 0,
          dayOfWeek: DateTime.thursday,
          now: _now,
        ),
        DateTime(2026, 9, 10, 8),
      );
    });

    test('monthly: this month while the day is ahead, else next month', () {
      expect(
        RecurringReminder.calcNextTrigger(
          frequency: ReminderFrequency.monthly,
          hour: 20,
          minute: 0,
          dayOfMonth: 5,
          now: _now,
        ),
        DateTime(2026, 9, 5, 20),
      );
      expect(
        RecurringReminder.calcNextTrigger(
          frequency: ReminderFrequency.monthly,
          hour: 20,
          minute: 0,
          dayOfMonth: 1,
          now: _now,
        ),
        DateTime(2026, 10, 1, 20),
      );
      // Day 29–31 is clamped so February never skips a month.
      expect(
        RecurringReminder.calcNextTrigger(
          frequency: ReminderFrequency.monthly,
          hour: 20,
          minute: 0,
          dayOfMonth: 31,
          now: _now,
        ),
        DateTime(2026, 9, 28, 20),
      );
    });
  });

  group('nextTriggerAfter', () {
    test('keeps a trigger that is still ahead', () {
      final reminder = _reminder(nextTrigger: DateTime(2026, 9, 5, 20));
      expect(reminder.isOverdueAt(_now), isFalse);
      expect(reminder.nextTriggerAfter(_now), DateTime(2026, 9, 5, 20));
    });

    test('moves an overdue trigger on to the next firing', () {
      // Fired on 5/8, swiped away: the row never advanced.
      final reminder = _reminder(nextTrigger: DateTime(2026, 8, 5, 20));
      expect(reminder.isOverdueAt(_now), isTrue);
      expect(reminder.nextTriggerAfter(_now), DateTime(2026, 9, 5, 20));
    });

    test('a trigger exactly at now counts as overdue', () {
      final reminder = _reminder(
        frequency: ReminderFrequency.daily,
        hour: 10,
        nextTrigger: _now,
      );
      expect(reminder.isOverdueAt(_now), isTrue);
      expect(reminder.nextTriggerAfter(_now), DateTime(2026, 9, 4, 10));
    });
  });

  group('warnTriggerAfter', () {
    test('is measured from the firing ahead, so an overdue row still warns', () {
      // Before: the warn time was derived from the stale 5/8 trigger, sat in
      // the past, and came back null — the warning was never armed again.
      final reminder = _reminder(
        nextTrigger: DateTime(2026, 8, 5, 20),
        warnBeforeHours: 48,
      );
      expect(reminder.warnTriggerAfter(_now), DateTime(2026, 9, 3, 20));
    });

    test('is null once the warning moment has passed', () {
      final reminder = _reminder(
        nextTrigger: DateTime(2026, 9, 4, 8),
        warnBeforeHours: 48,
      );
      expect(reminder.warnTriggerAfter(_now), isNull);
    });

    test('is null when warnings are off', () {
      final reminder = _reminder(nextTrigger: DateTime(2026, 9, 5, 20));
      expect(reminder.warnTriggerAfter(_now), isNull);
    });
  });
}
