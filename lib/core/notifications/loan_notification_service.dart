import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/loan/domain/installment_status.dart';
import '../../features/loan/domain/loan.dart';

/// Start of the id range instalment reminders live in.
///
/// The other schedulers sit well below: the daily nudge is 0, recurring
/// reminders take 1000–16999 (`reminder_notification_service.dart`), and the
/// two test notifications are 99 and 9999. Nothing reaches 20000.
const int kLoanIdBase = 20000;

/// How far the range runs, and so how many distinct ids a hash can produce.
const int _kLoanIdSpan = 10000;

/// How many instalments ahead of the next one are worth scheduling per loan.
///
/// A hundred-instalment loan does not need a hundred pending notifications;
/// the rest are scheduled as the app is opened, which happens far more often
/// than instalments come due.
const int kLoanScheduleWindow = 3;

/// The hour of the day a reminder fires, the day before the instalment is due.
const int kLoanReminderHour = 9;

/// Reminds about instalments that are coming due.
class LoanNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// The notification id for [installmentId].
  ///
  /// Derived from the id rather than stored, so the reminder can be cancelled
  /// later without keeping a table of what was scheduled.
  static int notificationId(String installmentId) =>
      kLoanIdBase + installmentId.hashCode.abs() % _kLoanIdSpan;

  /// When [dueDate]'s reminder should fire: 09:00 the morning before.
  static DateTime reminderTime(DateTime dueDate) => DateTime(
    dueDate.year,
    dueDate.month,
    dueDate.day,
    kLoanReminderHour,
  ).subtract(const Duration(days: 1));

  /// Which instalments of [loan] deserve a pending reminder right now.
  ///
  /// Only ones still owing money, only ones whose reminder time has not
  /// already passed, and only the first [kLoanScheduleWindow] of those — kept
  /// pure so the choice can be tested without a notification plugin.
  static List<InstallmentProgress> dueForReminder(
    Loan loan,
    List<InstallmentProgress> progress, {
    required DateTime now,
    int window = kLoanScheduleWindow,
  }) {
    if (loan.isClosed || loan.repaymentMode != RepaymentMode.installment) {
      return const [];
    }
    return progress
        .where((entry) => !entry.isSettled)
        .where(
          (entry) => reminderTime(entry.installment.dueDate).isAfter(now),
        )
        .take(window)
        .toList();
  }

  /// Replaces [loan]'s pending reminders with the ones it should have now.
  ///
  /// Every instalment of the loan is cancelled first, so an instalment that
  /// has since been paid, moved or deleted cannot leave a reminder behind.
  static Future<void> rescheduleLoan(
    Loan loan,
    List<InstallmentProgress> progress, {
    DateTime? now,
  }) async {
    for (final entry in progress) {
      await _plugin.cancel(notificationId(entry.installment.id));
    }

    final wanted = dueForReminder(
      loan,
      progress,
      now: now ?? DateTime.now(),
    );
    for (final entry in wanted) {
      await _schedule(loan, entry, progress.length);
    }
  }

  /// Drops every reminder of the given instalments — used when a schedule is
  /// deleted or the loan itself is.
  static Future<void> cancelAll(Iterable<String> installmentIds) async {
    for (final id in installmentIds) {
      await _plugin.cancel(notificationId(id));
    }
  }

  static Future<void> _schedule(
    Loan loan,
    InstallmentProgress entry,
    int total,
  ) async {
    final installment = entry.installment;
    final scheduled = tz.TZDateTime.from(
      reminderTime(installment.dueDate),
      tz.local,
    );

    final payload = jsonEncode({
      'loan_id': loan.id,
      'installment_id': installment.id,
      'amount': entry.shortfall.toString(),
    });

    final due = installment.dueDate;
    final verb = loan.type == LoanType.borrowed ? 'phải trả' : 'sẽ thu';

    await _plugin.zonedSchedule(
      notificationId(installment.id),
      '💸 Đợt ${installment.seq}/$total — ${loan.title}',
      'Ngày mai ${due.day}/${due.month} $verb '
          '${_fmt(entry.shortfall)} ₫.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'spendo_loan_due',
          'Nhắc đợt trả góp',
          channelDescription: 'Nhắc trước một ngày khi một đợt trả góp đến hạn',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          actions: [
            AndroidNotificationAction(
              'pay_installment',
              'Ghi thanh toán',
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
      // No matchDateTimeComponents: an instalment is due once, not every month.
      payload: payload,
    );
  }

  static String _fmt(int amount) => amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
}
