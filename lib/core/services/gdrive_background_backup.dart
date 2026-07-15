import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/powersync_db.dart';
import 'gdrive_auth_service.dart';
import 'gdrive_backup_service.dart';

const autoGDriveBackupTaskName = 'autoGDriveBackup';
const gdriveLastBackupTimeKey = 'gdrive_last_backup_time';

typedef AsyncOperation = Future<void> Function();

Future<bool> runGDriveBackgroundTask(
  String taskName, {
  AsyncOperation? openLocalDatabase,
  Future<bool> Function()? signInSilently,
  AsyncOperation? uploadBackup,
  Future<void> Function(DateTime time)? saveLastBackupTime,
  void Function(String message)? log,
}) async {
  if (taskName != autoGDriveBackupTaskName) return true;

  final writeLog = log ?? debugPrint;

  try {
    writeLog('[WorkManager] Starting autoGDriveBackup task');

    await (openLocalDatabase ?? _openLocalDatabaseForBackup)();

    final signedIn =
        await (signInSilently ?? GDriveAuthService.instance.signInSilently)();
    if (!signedIn) {
      writeLog('[WorkManager] Not signed in, aborting backup');
      return true;
    }

    await (uploadBackup ?? GDriveBackupService.instance.uploadBackup)();

    final now = DateTime.now();
    await (saveLastBackupTime ?? _saveLastBackupTime)(now);

    writeLog('[WorkManager] autoGDriveBackup completed successfully');
    return true;
  } catch (error) {
    writeLog('[WorkManager] Task failed: $error');
    return false;
  }
}

Future<void> _openLocalDatabaseForBackup() {
  return openDatabase(setupSync: false);
}

Future<void> _saveLastBackupTime(DateTime time) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(gdriveLastBackupTimeKey, time.millisecondsSinceEpoch);
}
