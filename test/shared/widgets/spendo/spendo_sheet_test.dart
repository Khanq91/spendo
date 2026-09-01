import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

/// Walks up from [finder] to the nearest ancestor that paints a colour.
Color? _paintedBackgroundOf(WidgetTester tester, Finder finder) {
  final containers = tester.widgetList<Container>(
    find.ancestor(of: finder, matching: find.byType(Container)),
  );
  for (final container in containers) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      return decoration.color;
    }
  }
  return null;
}

Future<void> _openSheet(WidgetTester tester, Widget content) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(AppColorScheme.roseDefault),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => SpendoSheet.showModal<void>(
              context: context,
              builder: (_) => content,
            ),
            child: const Text('Mở'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a plain widget still gets the sheet surface', (tester) async {
    // The barrier is transparent because SpendoSheet paints its own
    // background — content that is not a SpendoSheet used to render with no
    // background at all, showing whatever sheet was underneath.
    await _openSheet(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Nội dung chưa dựng lại'),
      ),
    );

    final painted = _paintedBackgroundOf(
      tester,
      find.text('Nội dung chưa dựng lại'),
    );
    expect(painted, isNotNull);
    expect(painted!.a, 1.0, reason: 'sheet must be opaque');
  });

  testWidgets('a SpendoSheet is not double-wrapped', (tester) async {
    await _openSheet(
      tester,
      const SpendoSheet(child: Text('Đã dựng lại')),
    );

    expect(find.byType(SpendoSheet), findsOneWidget);
    final painted = _paintedBackgroundOf(tester, find.text('Đã dựng lại'));
    expect(painted, isNotNull);
    expect(painted!.a, 1.0);
  });
}
