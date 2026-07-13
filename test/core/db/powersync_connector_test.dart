import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/db/powersync_connector.dart';

void main() {
  group('uploadCrudTransaction', () {
    test('completes the batch after every upload succeeds', () async {
      final events = <String>[];

      await uploadCrudTransaction(
        uploadOperations: () async => events.add('uploaded'),
        complete: () async => events.add('completed'),
      );

      expect(events, ['uploaded', 'completed']);
    });

    test('keeps the batch pending when an upload fails', () async {
      var completeCalls = 0;

      await expectLater(
        uploadCrudTransaction(
          uploadOperations: () async => throw StateError('network failure'),
          complete: () async {
            completeCalls++;
          },
        ),
        throwsStateError,
      );

      expect(completeCalls, 0);
    });
  });
}
