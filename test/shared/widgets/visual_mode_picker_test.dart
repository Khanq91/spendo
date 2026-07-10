import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/visual_mode_provider.dart';
import 'package:spendo/shared/widgets/visual_mode_picker.dart';

void main() {
  testWidgets('visual mode tile changes selection with one callback', (
    tester,
  ) async {
    var selectedMode = AppVisualMode.normal;
    var callbackCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder:
                (context, setState) => VisualModePicker(
                  selectedMode: selectedMode,
                  onChanged: (mode) {
                    callbackCount++;
                    setState(() => selectedMode = mode);
                  },
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Xịn xò'));
    await tester.pumpAndSettle();

    expect(selectedMode, AppVisualMode.fancy);
    expect(callbackCount, 1);
  });
}
