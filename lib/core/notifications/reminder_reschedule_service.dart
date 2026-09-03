import 'package:flutter/material.dart';
import '../../features/reminders/domain/recurring_reminder.dart';
import '../db/powersync_db.dart';
import 'reminder_notification_service.dart';

/// Cập nhật nextTrigger trong DB và reschedule notification
/// sau khi một recurring reminder đã fire.
class ReminderRescheduleService {
  static Future<void> rescheduleAfterFire(String reminderId) async {
    try {
      final row = await db.getOptional(
        'SELECT * FROM recurring_reminders WHERE id = ? AND is_active = 1',
        [reminderId],
      );
      if (row == null) return;

      final reminder = RecurringReminder.fromMap(row);

      // Tính nextTrigger kế tiếp từ thời điểm hiện tại
      final nextTrigger = RecurringReminder.calcNextTrigger(
        frequency: reminder.frequency,
        hour: reminder.hour,
        minute: reminder.minute,
        dayOfWeek: reminder.dayOfWeek,
        dayOfMonth: reminder.dayOfMonth,
      );

      // Update DB
      await db.execute(
        'UPDATE recurring_reminders SET next_trigger = ? WHERE id = ?',
        [nextTrigger.toIso8601String(), reminderId],
      );

      // Reschedule notification với nextTrigger mới
      final updated = reminder.copyWith(nextTrigger: nextTrigger);
      await ReminderNotificationService.schedule(updated);

      debugPrint('[ReminderReschedule] $reminderId → $nextTrigger');
    } catch (e) {
      debugPrint('[ReminderReschedule] error: $e');
    }
  }

  /// Moves every active reminder whose stored trigger is already behind [now]
  /// on to its next firing, and returns the list as it stands afterwards.
  ///
  /// The row used to advance only when the notification was tapped
  /// ([rescheduleAfterFire]); one swiped away or ignored kept a trigger in the
  /// past, so the tile said "Lần tới" with a stale date and the warn
  /// notification — computed from that trigger — was never armed again. This
  /// runs at startup and after a restore, ahead of the scheduling pass, so the
  /// alarms are set from corrected rows. Rows that fail to persist are
  /// returned unchanged rather than failing the whole pass.
  static Future<List<RecurringReminder>> catchUp(
    List<RecurringReminder> reminders, {
    DateTime? now,
    Future<void> Function(RecurringReminder updated)? persist,
  }) async {
    final at = now ?? DateTime.now();
    final write = persist ?? _persistNextTrigger;
    final result = <RecurringReminder>[];
    for (final reminder in reminders) {
      if (!reminder.isActive || !reminder.isOverdueAt(at)) {
        result.add(reminder);
        continue;
      }
      final updated = reminder.copyWith(
        nextTrigger: reminder.nextTriggerAfter(at),
      );
      try {
        await write(updated);
        result.add(updated);
      } catch (e) {
        debugPrint('[ReminderReschedule] catch-up ${reminder.id}: $e');
        result.add(reminder);
      }
    }
    return result;
  }

  static Future<void> _persistNextTrigger(RecurringReminder reminder) {
    return db.execute(
      'UPDATE recurring_reminders SET next_trigger = ? WHERE id = ?',
      [reminder.nextTrigger.toIso8601String(), reminder.id],
    );
  }
}