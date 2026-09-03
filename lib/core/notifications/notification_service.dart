import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'reminder_reschedule_service.dart';

/// The route an instalment reminder's payload asks for, or null when the
/// payload is not one — a recurring reminder's, say.
///
/// Split out from the handler so the deep link can be checked without a
/// navigator: the handler itself can only be exercised by tapping a real
/// notification.
String? loanPaymentPath(Map<String, dynamic> payload) {
  final loanId = payload['loan_id'];
  if (loanId is! String || loanId.isEmpty) return null;

  final amount = payload['amount'];
  final query = StringBuffer('loan_id=${Uri.encodeComponent(loanId)}');
  if (amount is String && amount.isNotEmpty) {
    query.write('&amount=${Uri.encodeComponent(amount)}');
  }
  return '/loan-pay?$query';
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static GlobalKey<NavigatorState>? navigatorKey;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      final timezoneName = await FlutterTimezone.getLocalTimezone()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () => 'Asia/Ho_Chi_Minh',
      );
      tz.setLocalLocation(tz.getLocation(timezoneName));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);

      await _plugin
          .initialize(
        settings,
        onDidReceiveNotificationResponse: _onResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
      )
          .timeout(const Duration(seconds: 5), onTimeout: () => null);

      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] init error: $e');
      _initialized = true;
    }
  }

  static void _onResponse(NotificationResponse response) {
    _handlePayload(response.payload, response.actionId);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse response) {
    _handlePayload(response.payload, response.actionId);
  }

  static void _handlePayload(String? payload, String? actionId) {
    if (actionId == 'dismiss' || payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      // An instalment reminder goes straight to its loan with the payment
      // sheet already open — a different destination from the recurring
      // reminders below, so it is answered first.
      final loanPath = loanPaymentPath(data);
      if (loanPath != null) {
        final context = navigatorKey?.currentContext;
        if (context != null) GoRouter.of(context).go(loanPath);
        return;
      }

      final reminderId = data['reminder_id'] as String?;
      final categoryId = data['category_id'] as String?;
      final note = Uri.encodeComponent(data['note'] as String? ?? '');
      final amount = data['amount'] as String? ?? '';

      // Reschedule nextTrigger sau khi reminder fire (chạy async, không block)
      if (reminderId != null && reminderId.isNotEmpty) {
        Future.microtask(
              () => ReminderRescheduleService.rescheduleAfterFire(reminderId),
        );
      }

      // 'dismiss' action đã handled ở trên — chỉ navigate khi tap body hoặc 'add_expense'
      String path = '/add';
      final params = <String>[];
      if (categoryId != null && categoryId.isNotEmpty) {
        params.add('category_id=$categoryId');
      }
      if (note.isNotEmpty) params.add('note=$note');
      if (amount.isNotEmpty) params.add('amount=$amount');
      if (params.isNotEmpty) path = '$path?${params.join('&')}';

      final context = navigatorKey?.currentContext;
      if (context != null) {
        GoRouter.of(context).go(path);
      }
    } catch (_) {}
  }

  static Future<void> handleLaunchNotification(BuildContext context) async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      final response = details!.notificationResponse;
      _handlePayload(response?.payload, response?.actionId);
    }
  }

  static Future<void> scheduleDailyReminder({
    int hour = 21,
    int minute = 0,
  }) async {
    await _plugin.cancel(0);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      0,
      'Spendo 💸',
      'Hôm nay bạn đã ghi lại chi tiêu chưa?',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'spendo_daily',
          'Nhắc nhập chi tiêu',
          channelDescription: 'Nhắc nhở nhập chi tiêu hàng ngày',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder() async {
    await _plugin.cancel(0);
  }

  /// Drops every pending notification this app scheduled — the daily nudge,
  /// per-reminder and instalment alarms alike. Used by the data reset.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Asks for the notification permission where there is one to ask for, and
  /// answers as if granted where there is not.
  ///
  /// Only an explicit refusal comes back `false`: below Android 13 the plugin
  /// answers `null`, and without the plugin (tests) the channel throws —
  /// neither is a reason to warn the user. Recurring reminders and instalment
  /// schedules call this when they are created, because until now only the
  /// daily-nudge switch ever asked, and a reminder made on a fresh Android 13
  /// install simply never showed. The switch keeps [requestPermission], whose
  /// strict answer is what it toggles on.
  static Future<bool> ensurePermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;
      return await android.requestNotificationsPermission() ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> sendTestNotification() async {
    final scheduled =
    tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

    await _plugin.zonedSchedule(
      99,
      'Spendo 💸',
      'Hôm nay bạn đã ghi lại chi tiêu chưa?',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'spendo_daily',
          'Nhắc nhập chi tiêu',
          channelDescription: 'Nhắc nhở nhập chi tiêu hàng ngày',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
