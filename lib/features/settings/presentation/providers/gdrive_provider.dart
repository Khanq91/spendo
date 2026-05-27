import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/services/gdrive_auth_service.dart';
import '../../../../core/services/gdrive_backup_service.dart';

// ── Backup frequency enum ────────────────────────────────────────────────────

enum BackupFrequency {
  none,
  daily,
  weekly,
  monthly;

  String get label => switch (this) {
    none => 'Tắt',
    daily => 'Hàng ngày',
    weekly => 'Hàng tuần',
    monthly => 'Hàng tháng',
  };

  Duration get interval => switch (this) {
    none => Duration.zero,
    daily => const Duration(days: 1),
    weekly => const Duration(days: 7),
    monthly => const Duration(days: 30),
  };
}

// ── State class ──────────────────────────────────────────────────────────────

class GDriveState {
  final bool isSignedIn;
  final String? email;
  final DateTime? lastBackupTime;
  final BackupFrequency frequency;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const GDriveState({
    this.isSignedIn = false,
    this.email,
    this.lastBackupTime,
    this.frequency = BackupFrequency.none,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  GDriveState copyWith({
    bool? isSignedIn,
    String? email,
    DateTime? lastBackupTime,
    BackupFrequency? frequency,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return GDriveState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      email: email ?? this.email,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      frequency: frequency ?? this.frequency,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// ── SharedPreferences keys ───────────────────────────────────────────────────

const _kFrequencyKey = 'gdrive_backup_frequency';
const _kLastBackupKey = 'gdrive_last_backup_time';

// ── Provider ─────────────────────────────────────────────────────────────────

final gdriveProvider = StateNotifierProvider<GDriveNotifier, GDriveState>(
  (ref) => GDriveNotifier(),
);

class GDriveNotifier extends StateNotifier<GDriveState> {
  GDriveNotifier() : super(const GDriveState()) {
    _init();
  }

  final _auth = GDriveAuthService.instance;
  final _backup = GDriveBackupService.instance;

  Future<void> _init() async {
    // Load saved preferences
    final prefs = await SharedPreferences.getInstance();
    final freqIndex = prefs.getInt(_kFrequencyKey) ?? 0;
    final lastMs = prefs.getInt(_kLastBackupKey);

    // Try silent sign-in
    final signedIn = await _auth.signInSilently();

    state = state.copyWith(
      isSignedIn: signedIn,
      email: _auth.currentEmail,
      frequency: BackupFrequency.values[freqIndex],
      lastBackupTime:
          lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null,
    );

    // Auto-backup check on app open
    if (signedIn) {
      await _checkAutoBackup();
    }
  }

  /// Interactive Google Sign-In.
  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, error: null);
    final success = await _auth.signIn();

    if (success) {
      state = state.copyWith(
        isSignedIn: true,
        email: _auth.currentEmail,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Đăng nhập thất bại. Thử lại.',
      );
    }
  }

  /// Sign out from Google.
  Future<void> signOut() async {
    await _auth.signOut();
    state = const GDriveState(); // reset
    // Keep frequency setting
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastBackupKey);
    // Cancel any scheduled tasks
    await Workmanager().cancelByUniqueName('autoGDriveBackupTask');
  }

  /// Manually trigger a backup now.
  Future<void> backupNow() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _backup.uploadBackup();
      final now = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastBackupKey, now.millisecondsSinceEpoch);

      state = state.copyWith(
        isLoading: false,
        lastBackupTime: now,
        successMessage: 'Backup thành công!',
      );
    } catch (e) {
      debugPrint('[GDrive] Backup error: $e');
      state = state.copyWith(isLoading: false, error: 'Lỗi backup: $e');
    }
  }

  /// Set auto-backup frequency.
  Future<void> setFrequency(BackupFrequency freq) async {
    state = state.copyWith(frequency: freq);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFrequencyKey, freq.index);

    // Update WorkManager task
    if (freq == BackupFrequency.none) {
      await Workmanager().cancelByUniqueName('autoGDriveBackupTask');
    } else {
      await Workmanager().registerPeriodicTask(
        'autoGDriveBackupTask',
        'autoGDriveBackup',
        frequency: freq.interval,
        constraints: Constraints(
          networkType: NetworkType.unmetered, // Require Wi-Fi
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );
    }
  }

  /// List backups on Drive.
  Future<List<DriveBackupInfo>> listBackups() async {
    return _backup.listBackups();
  }

  /// Auto-backup check: runs on app open, backs up silently if due.
  Future<void> _checkAutoBackup() async {
    if (state.frequency == BackupFrequency.none) return;

    final now = DateTime.now();
    final last = state.lastBackupTime;

    // If never backed up, or enough time has passed
    if (last == null || now.difference(last) >= state.frequency.interval) {
      try {
        debugPrint('[GDrive] Auto-backup triggered (${state.frequency.label})');
        await _backup.uploadBackup();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kLastBackupKey, now.millisecondsSinceEpoch);

        state = state.copyWith(lastBackupTime: now);
        debugPrint('[GDrive] Auto-backup completed');
      } catch (e) {
        debugPrint('[GDrive] Auto-backup failed: $e');
      }
    }
  }
}
