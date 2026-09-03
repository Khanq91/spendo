import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/notifications/reminder_reschedule_service.dart';
import 'package:spendo/features/reminders/domain/recurring_reminder.dart';

final _now = DateTime(2026, 9, 3, 10);

RecurringReminder _reminder(
  String id,
  DateTime nextTrigger, {
  bool active = true,
}) => RecurringReminder(
  id: id,
  title: id,
  categoryId: 'bills',
  frequency: ReminderFrequency.monthly,
  dayOfMonth: 5,
  hour: 20,
  minute: 0,
  isActive: active,
  nextTrigger: nextTrigger,
);

void main() {
  test('moves only overdue, active reminders on, and persists them', () async {
    final written = <String, DateTime>{};

    final result = await ReminderRescheduleService.catchUp(
      [
        _reminder('overdue', DateTime(2026, 8, 5, 20)),
        _reminder('ahead', DateTime(2026, 9, 5, 20)),
        _reminder('off', DateTime(2026, 8, 5, 20), active: false),
      ],
      now: _now,
      persist: (reminder) async => written[reminder.id] = reminder.nextTrigger,
    );

    expect(written, {'overdue': DateTime(2026, 9, 5, 20)});
    expect(result.map((r) => r.id), ['overdue', 'ahead', 'off']);
    expect(result.map((r) => r.nextTrigger), [
      DateTime(2026, 9, 5, 20),
      DateTime(2026, 9, 5, 20),
      DateTime(2026, 8, 5, 20),
    ]);
  });

  test('a row that fails to persist comes back unchanged; the pass goes on', () async {
    final written = <String>[];

    final result = await ReminderRescheduleService.catchUp(
      [
        _reminder('a', DateTime(2026, 8, 5, 20)),
        _reminder('b', DateTime(2026, 8, 5, 20)),
      ],
      now: _now,
      persist: (reminder) async {
        if (reminder.id == 'a') throw StateError('db closed');
        written.add(reminder.id);
      },
    );

    expect(written, ['b']);
    expect(result.first.nextTrigger, DateTime(2026, 8, 5, 20));
    expect(result.last.nextTrigger, DateTime(2026, 9, 5, 20));
  });
}
