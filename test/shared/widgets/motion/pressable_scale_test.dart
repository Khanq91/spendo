import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/shared/widgets/motion/motion.dart';

void main() {
  testWidgets('deferred tap keeps the child callback single', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PressableScale(
            deferTapToChild: true,
            child: FilledButton(
              onPressed: () => tapCount++,
              child: const Text('Add'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(tapCount, 1);
  });
}
