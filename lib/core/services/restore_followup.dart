import 'package:flutter/foundation.dart';

import '../../features/reminders/data/reminder_repository.dart';
import '../notifications/loan_reschedule_service.dart';
import '../notifications/reminder_notification_service.dart';
import '../notifications/reminder_reschedule_service.dart';
import '../utils/widget_sync.dart';

typedef RestoreStep = Future<void> Function();

/// What has to happen once a backup has been written into the database.
///
/// Restoring used to invalidate two providers and stop there: the reminders
/// and instalment schedules it brought back only got their alarms on the next
/// cold start (`main.dart` does that pass), and the home-screen widget kept
/// showing the categories from before. This is that start-up pass, callable
/// from the restore itself.
///
/// Every step is best-effort and runs even when the one before it failed: an
/// alarm that would not schedule is not a reason to report the restore — the
/// data is already in — as failed.
Future<void> runRestoreFollowUp({
  RestoreStep? scheduleReminders,
  RestoreStep? scheduleInstalments,
  RestoreStep? syncWidgets,
  void Function(String message)? log,
}) async {
  final writeLog = log ?? debugPrint;
  final steps = <(String, RestoreStep)>[
    ('reminders', scheduleReminders ?? _scheduleReminders),
    ('instalments', scheduleInstalments ?? LoanRescheduleService.rescheduleAll),
    ('widgets', syncWidgets ?? WidgetSync.syncCategories),
  ];
  for (final (name, step) in steps) {
    try {
      await step();
    } catch (e) {
      writeLog('[Restore] $name: $e');
    }
  }
}

/// Same order as start-up: bring overdue rows forward, then arm the alarms.
Future<void> _scheduleReminders() async {
  final reminders = await ReminderRepository().getAll();
  final current = await ReminderRescheduleService.catchUp(reminders);
  await ReminderNotificationService.scheduleAll(current);
}
