import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../features/reminders/domain/recurring_reminder.dart';

/// Notification IDs for recurring reminders start at 1000
/// to avoid conflict with daily reminder (0) and test (99).
const _kReminderIdBase = 1000;

class ReminderNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Must be called after NotificationService.init()
  static Future<void> scheduleAll(List<RecurringReminder> reminders) async {
    for (final r in reminders) {
      if (r.isActive) {
        await schedule(r);
      }
    }
  }

  static Future<void> schedule(RecurringReminder r) async {
    final notifId = _notifId(r.id);
    await _plugin.cancel(notifId);

    final payload = jsonEncode({
      'reminder_id': r.id,
      'category_id': r.categoryId,
      'note': r.title,
      'amount': r.amountHint?.toString() ?? '',
    });

    final scheduled = tz.TZDateTime.from(r.nextTrigger, tz.local);

    DateTimeComponents? matchComponents;
    matchComponents = switch (r.frequency) {
      ReminderFrequency.daily => DateTimeComponents.time,
      ReminderFrequency.weekly => DateTimeComponents.dayOfWeekAndTime,
      ReminderFrequency.monthly => DateTimeComponents.dayOfMonthAndTime,
    };

    await _plugin.zonedSchedule(
      notifId,
      '💸 ${r.title}',
      'Đã đến lúc ghi chi tiêu: ${r.title}${r.amountHint != null ? ' (~${_fmt(r.amountHint!)} ₫)' : ''}',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'spendo_reminders',
          'Nhắc chi tiêu định kỳ',
          channelDescription: 'Nhắc nhở mua đồ và ghi chi tiêu định kỳ',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          actions: [
            AndroidNotificationAction(
              'add_expense',
              'Thêm ngay',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'dismiss',
              'Bỏ qua',
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
      payload: payload,
    );
  }

  static Future<void> cancel(String reminderId) async {
    await _plugin.cancel(_notifId(reminderId));
  }

  static int _notifId(String reminderId) {
    return _kReminderIdBase + reminderId.hashCode.abs() % 8000;
  }

  static String _fmt(int amount) {
    return amount
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}