import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../db/powersync_db.dart';
import '../notifications/notification_service.dart';
import '../utils/widget_sync.dart';

/// What a reset is about to erase, for the confirmation screen.
class ResetDataSummary {
  const ResetDataSummary({
    required this.transactions,
    required this.wallets,
    required this.loans,
    required this.reminders,
    required this.customCategories,
    required this.budgets,
  });

  final int transactions;
  final int wallets;

  /// Loans and tracking-only "sổ theo dõi" entries together.
  final int loans;
  final int reminders;
  final int customCategories;

  /// Monthly and per-category budgets together.
  final int budgets;
}

typedef ResetStep = Future<void> Function();

/// Puts the app back to its first-install state: every local table, every
/// preference, every scheduled notification, the home-screen widgets and the
/// Google Drive session on this device. Files already on Drive are kept.
///
/// Every step is injectable so tests can pin the order without a device.
class ResetDataService {
  ResetDataService({
    ResetStep? cancelBackgroundTasks,
    ResetStep? cancelNotifications,
    ResetStep? signOutDrive,
    ResetStep? clearDatabase,
    ResetStep? clearPreferences,
    ResetStep? clearTemporaryFiles,
    ResetStep? syncWidgets,
  }) : _cancelBackgroundTasks =
           cancelBackgroundTasks ?? _defaultCancelBackgroundTasks,
       _cancelNotifications = cancelNotifications ?? NotificationService.cancelAll,
       // Signing out of Drive lives in the settings provider; the caller
       // passes it in so this service stays free of feature imports.
       _signOutDrive = signOutDrive ?? _noop,
       _clearDatabase = clearDatabase ?? resetLocalDatabase,
       _clearPreferences = clearPreferences ?? _defaultClearPreferences,
       _clearTemporaryFiles =
           clearTemporaryFiles ?? _defaultClearTemporaryFiles,
       _syncWidgets = syncWidgets ?? WidgetSync.syncCategories;

  final ResetStep _cancelBackgroundTasks;
  final ResetStep _cancelNotifications;
  final ResetStep _signOutDrive;
  final ResetStep _clearDatabase;
  final ResetStep _clearPreferences;
  final ResetStep _clearTemporaryFiles;
  final ResetStep _syncWidgets;

  /// Counts what the reset would erase.
  static Future<ResetDataSummary> summarize([
    PowerSyncDatabase? database,
  ]) async {
    final target = database ?? db;
    Future<int> count(String sql) async {
      final row = await target.get(sql);
      return (row['n'] as int?) ?? 0;
    }

    return ResetDataSummary(
      transactions: await count('SELECT COUNT(*) AS n FROM transactions'),
      wallets: await count('SELECT COUNT(*) AS n FROM wallets'),
      loans: await count('SELECT COUNT(*) AS n FROM loans'),
      reminders: await count('SELECT COUNT(*) AS n FROM recurring_reminders'),
      customCategories: await count(
        'SELECT COUNT(*) AS n FROM categories WHERE COALESCE(is_default, 0) = 0',
      ),
      budgets:
          await count('SELECT COUNT(*) AS n FROM budgets') +
          await count('SELECT COUNT(*) AS n FROM category_budgets'),
    );
  }

  /// Runs the reset, in an order where nothing can re-create data behind it.
  ///
  /// The database step must succeed and rethrows; the others log and carry
  /// on, so a missing plugin never leaves the data half-deleted.
  Future<void> run() async {
    // Background work first, so nothing uploads or re-schedules while the
    // rest is being cleared.
    await _bestEffort('background tasks', _cancelBackgroundTasks);
    await _bestEffort('notifications', _cancelNotifications);
    await _bestEffort('drive sign-out', _signOutDrive);
    await _clearDatabase();
    await _bestEffort('preferences', _clearPreferences);
    await _bestEffort('temporary files', _clearTemporaryFiles);
    // Last: the widgets re-read the fresh defaults and the empty pins.
    await _bestEffort('widgets', _syncWidgets);
  }

  static Future<void> _bestEffort(String what, ResetStep step) async {
    try {
      await step();
    } catch (e) {
      debugPrint('[ResetData] $what: $e');
    }
  }

  static Future<void> _noop() async {}

  static Future<void> _defaultCancelBackgroundTasks() =>
      Workmanager().cancelByUniqueName('autoGDriveBackupTask');

  static Future<void> _defaultClearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Exports and backups are written to the temp dir as `spendo_*`; only
  /// those go, the rest of the directory belongs to the engine.
  static Future<void> _defaultClearTemporaryFiles() async {
    final dir = await getTemporaryDirectory();
    await for (final entity in dir.list()) {
      if (entity is File && p.basename(entity.path).startsWith('spendo_')) {
        await entity.delete();
      }
    }
  }
}
