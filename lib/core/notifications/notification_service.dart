import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) {},
    );

    _initialized = true;
  }

  /// Đặt lịch nhắc nhở hàng ngày lúc [hour]:[minute]
  static Future<void> scheduleDailyReminder({
    int hour = 21,
    int minute = 0,
  }) async {
    await _plugin.cancel(0); // cancel cái cũ nếu có

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Nếu giờ đã qua thì đặt cho ngày mai
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

  /// Test notification — hiện sau 5 giây
  static Future<void> sendTestNotification() async {
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

    await _plugin.zonedSchedule(
      99, // id riêng, không ảnh hưởng daily reminder
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