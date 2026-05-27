import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';

import '../utils/backup_service.dart';
import 'gdrive_auth_service.dart';

/// Metadata for a backup file stored on Google Drive.
class DriveBackupInfo {
  final String fileId;
  final String name;
  final DateTime? createdTime;
  final int? sizeBytes;

  const DriveBackupInfo({
    required this.fileId,
    required this.name,
    this.createdTime,
    this.sizeBytes,
  });
}

/// Handles upload / download / list / cleanup of backups on Google Drive.
class GDriveBackupService {
  GDriveBackupService._();
  static final instance = GDriveBackupService._();

  /// Max backups to keep on Drive — older ones are auto-deleted.
  static const _kMaxBackups = 5;

  // ── Upload ──────────────────────────────────────────────────────────────────

  /// Export current app data and upload to Google Drive's appData folder.
  Future<void> uploadBackup() async {
    final driveApi = await GDriveAuthService.instance.getDriveApi();
    if (driveApi == null) throw Exception('Chưa đăng nhập Google');

    // 1. Export backup as JSON string (reuses existing BackupService)
    final jsonString = await BackupService.exportBackupAsString();

    // 2. Create file metadata
    final now = DateTime.now();
    final fileName = 'spendo_backup_'
        '${now.year}${_pad(now.month)}${_pad(now.day)}_'
        '${_pad(now.hour)}${_pad(now.minute)}.json';

    final fileMetadata = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder']
      ..mimeType = 'application/json';

    // 3. Upload
    final bytes = utf8.encode(jsonString);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
    );

    await driveApi.files.create(fileMetadata, uploadMedia: media);
    debugPrint('[GDrive] Backup uploaded: $fileName (${bytes.length} bytes)');

    // 4. Cleanup old backups
    await _cleanupOldBackups(driveApi);
  }

  // ── List ────────────────────────────────────────────────────────────────────

  /// List all backup files on Drive, most recent first.
  Future<List<DriveBackupInfo>> listBackups() async {
    final driveApi = await GDriveAuthService.instance.getDriveApi();
    if (driveApi == null) throw Exception('Chưa đăng nhập Google');

    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name contains 'spendo_backup_' and mimeType = 'application/json'",
      orderBy: 'createdTime desc',
      $fields: 'files(id, name, createdTime, size)',
    );

    return (fileList.files ?? [])
        .map((f) => DriveBackupInfo(
              fileId: f.id!,
              name: f.name ?? '',
              createdTime: f.createdTime,
              sizeBytes: f.size != null ? int.tryParse(f.size!) : null,
            ))
        .toList();
  }

  // ── Download ────────────────────────────────────────────────────────────────

  /// Download a backup file's JSON content.
  Future<String> downloadBackup(String fileId) async {
    final driveApi = await GDriveAuthService.instance.getDriveApi();
    if (driveApi == null) throw Exception('Chưa đăng nhập Google');

    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }

  // ── Restore ─────────────────────────────────────────────────────────────────

  /// Download a backup from Drive and restore it using BackupService.
  Future<RestoreResult> restoreFromDrive(String fileId) async {
    final jsonContent = await downloadBackup(fileId);

    // Write to temp file for BackupService.restore()
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/gdrive_restore_temp.json');
    await tempFile.writeAsString(jsonContent, encoding: utf8);

    return BackupService.restore(tempFile.path);
  }

  /// Preview what a restore would do (dry-run).
  Future<RestoreResult> previewRestoreFromDrive(String fileId) async {
    final jsonContent = await downloadBackup(fileId);

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/gdrive_restore_temp.json');
    await tempFile.writeAsString(jsonContent, encoding: utf8);

    return BackupService.previewRestore(tempFile.path);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Check if a recent backup exists (within the last 30 days).
  Future<bool> hasRecentBackup() async {
    try {
      final backups = await listBackups();
      if (backups.isEmpty) return false;
      final latest = backups.first;
      if (latest.createdTime == null) return false;
      final age = DateTime.now().difference(latest.createdTime!);
      return age.inDays <= 30;
    } catch (_) {
      return false;
    }
  }

  /// Delete old backups, keeping only [_kMaxBackups] most recent.
  Future<void> _cleanupOldBackups(drive.DriveApi driveApi) async {
    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name contains 'spendo_backup_' and mimeType = 'application/json'",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name)',
      );

      final files = fileList.files ?? [];
      if (files.length <= _kMaxBackups) return;

      // Delete files beyond the keep limit
      for (int i = _kMaxBackups; i < files.length; i++) {
        await driveApi.files.delete(files[i].id!);
        debugPrint('[GDrive] Deleted old backup: ${files[i].name}');
      }
    } catch (e) {
      debugPrint('[GDrive] Cleanup error: $e');
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
