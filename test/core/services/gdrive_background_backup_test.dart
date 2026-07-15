import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/services/gdrive_background_backup.dart';

void main() {
  group('runGDriveBackgroundTask', () {
    test('backs up from a local-only database in the required order', () async {
      final events = <String>[];
      DateTime? savedAt;

      final succeeded = await runGDriveBackgroundTask(
        autoGDriveBackupTaskName,
        openLocalDatabase: () async => events.add('database'),
        signInSilently: () async {
          events.add('sign-in');
          return true;
        },
        uploadBackup: () async => events.add('upload'),
        saveLastBackupTime: (time) async {
          events.add('timestamp');
          savedAt = time;
        },
        log: (_) {},
      );

      expect(succeeded, isTrue);
      expect(events, ['database', 'sign-in', 'upload', 'timestamp']);
      expect(savedAt, isNotNull);
    });

    test(
      'stops successfully when Google silent sign-in is unavailable',
      () async {
        final events = <String>[];

        final succeeded = await runGDriveBackgroundTask(
          autoGDriveBackupTaskName,
          openLocalDatabase: () async => events.add('database'),
          signInSilently: () async {
            events.add('sign-in');
            return false;
          },
          uploadBackup: () async => events.add('upload'),
          saveLastBackupTime: (_) async => events.add('timestamp'),
          log: (_) {},
        );

        expect(succeeded, isTrue);
        expect(events, ['database', 'sign-in']);
      },
    );

    test(
      'reports failure without saving a timestamp when upload throws',
      () async {
        var timestampWrites = 0;

        final succeeded = await runGDriveBackgroundTask(
          autoGDriveBackupTaskName,
          openLocalDatabase: () async {},
          signInSilently: () async => true,
          uploadBackup: () async => throw StateError('Drive unavailable'),
          saveLastBackupTime: (_) async => timestampWrites++,
          log: (_) {},
        );

        expect(succeeded, isFalse);
        expect(timestampWrites, 0);
      },
    );

    test('ignores unrelated WorkManager tasks', () async {
      var databaseOpens = 0;

      final succeeded = await runGDriveBackgroundTask(
        'unrelatedTask',
        openLocalDatabase: () async => databaseOpens++,
        log: (_) {},
      );

      expect(succeeded, isTrue);
      expect(databaseOpens, 0);
    });
  });
}
