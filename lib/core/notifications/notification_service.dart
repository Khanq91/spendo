import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Injected after app starts — used to navigate on notification tap
  static GlobalKey<NavigatorState>? navigatorKey;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );

    _initialized = true;
  }

  static void _onResponse(NotificationResponse response) {
    _handlePayload(response.payload, response.actionId);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse response) {
    _handlePayload(response.payload, response.actionId);
  }

  static void _handlePayload(String? payload, String? actionId) {
    // 'dismiss' action → do nothing
    if (actionId == 'dismiss' || payload == null) return;

    // 'add_expense' action or tap on body → navigate to /add
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final categoryId = data['category_id'] as String?;
      final note = Uri.encodeComponent(data['note'] as String? ?? '');
      final amount = data['amount'] as String? ?? '';

      String path = '/add';
      final params = <String>[];
      if (categoryId != null && categoryId.isNotEmpty) {
        params.add('category_id=$categoryId');
      }
      if (note.isNotEmpty) params.add('note=$note');
      if (amount.isNotEmpty) params.add('amount=$amount');
      if (params.isNotEmpty) path = '$path?${params.join('&')}';

      // Navigate — works if app is in foreground or background
      final context = navigatorKey?.currentContext;
      if (context != null) {
        GoRouter.of(context).go(path);
      }
    } catch (_) {}
  }

  /// Handle the case where app was fully killed and launched via notification
  static Future<void> handleLaunchNotification(BuildContext context) async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      final response = details!.notificationResponse;
      _handlePayload(response?.payload, response?.actionId);
    }
  }

  /// Đặt lịch nhắc nhở hàng ngày lúc [hour]:[minute]
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

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation
    <AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  static Future<void> sendTestNotification() async {
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

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