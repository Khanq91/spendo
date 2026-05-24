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
}