import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/services/restore_followup.dart';

void main() {
  test('re-arms reminders, then instalments, then the widget', () async {
    final events = <String>[];

    await runRestoreFollowUp(
      scheduleReminders: () async => events.add('reminders'),
      scheduleInstalments: () async => events.add('instalments'),
      syncWidgets: () async => events.add('widgets'),
      log: (_) {},
    );

    expect(events, ['reminders', 'instalments', 'widgets']);
  });

  test('a step that fails is logged and the rest still run', () async {
    final events = <String>[];
    final logged = <String>[];

    await runRestoreFollowUp(
      scheduleReminders: () async => throw StateError('no plugin'),
      scheduleInstalments: () async => events.add('instalments'),
      syncWidgets: () async => events.add('widgets'),
      log: logged.add,
    );

    expect(events, ['instalments', 'widgets']);
    expect(logged.single, contains('reminders'));
  });
}
