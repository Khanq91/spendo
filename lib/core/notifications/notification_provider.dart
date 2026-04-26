import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

final notificationEnabledProvider =
StateNotifierProvider<NotificationNotifier, bool>(
      (ref) => NotificationNotifier(),
);

final notificationHourProvider =
StateNotifierProvider<NotificationHourNotifier, int>(
      (ref) => NotificationHourNotifier(),
);

final notificationMinuteProvider =
StateNotifierProvider<NotificationMinuteNotifier, int>(
      (ref) => NotificationMinuteNotifier(),
);

class NotificationNotifier extends StateNotifier<bool> {
  NotificationNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notif_enabled') ?? false;
  }

  Future<void> toggle(bool value, {required int hour, required int minute}) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', value);

    if (value) {
      await NotificationService.scheduleDailyReminder(
          hour: hour, minute: minute);
    } else {
      await NotificationService.cancelReminder();
    }
  }
}

class NotificationHourNotifier extends StateNotifier<int> {
  NotificationHourNotifier() : super(21) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('notif_hour') ?? 21;
  }

  Future<void> set(int hour) async {
    state = hour;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_hour', hour);
  }
}

class NotificationMinuteNotifier extends StateNotifier<int> {
  NotificationMinuteNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('notif_minute') ?? 0;
  }

  Future<void> set(int minute) async {
    state = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_minute', minute);
  }
}