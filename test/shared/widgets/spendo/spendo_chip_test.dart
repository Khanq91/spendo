import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

Color _fillOf(WidgetTester tester, String label) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.widgetWithText(SpendoChip, label),
          matching: find.byType(Container),
        )
        .last,
  );
  return (container.decoration! as ShapeDecoration).color!;
}

Future<void> _pump(WidgetTester tester, ThemeData theme, List<Widget> chips) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Wrap(spacing: 8, children: chips)),
    ),
  );
}

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light(AppColorScheme.roseDefault)),
    ('dark', AppTheme.dark(AppColorScheme.roseDefault)),
  ]) {
    testWidgets('every chip variant is filled and opaque in $name', (
      tester,
    ) async {
      await _pump(tester, theme, [
        const SpendoChip(label: 'Lọc'),
        const SpendoChip(label: 'Đang chọn', selected: true),
        SpendoChip.suggestion(label: 'Gợi ý', onTap: () {}),
        SpendoChip.meta(label: 'Meta', onTap: () {}),
      ]);
      await tester.pumpAndSettle();

      // An outline-only chip disappears against the dark surfaces, so every
      // variant carries a fill. This is what made the same affordance look
      // like two different controls across screens.
      for (final label in ['Lọc', 'Đang chọn', 'Gợi ý', 'Meta']) {
        final fill = _fillOf(tester, label);
        expect(fill.a, 1.0, reason: '$label chip must be opaque in $name');
      }
    });

    testWidgets('a suggestion chip matches a filter chip in $name', (
      tester,
    ) async {
      await _pump(tester, theme, [
        const SpendoChip(label: 'Lọc'),
        SpendoChip.suggestion(label: 'Gợi ý', onTap: () {}),
      ]);
      await tester.pumpAndSettle();

      // The two used to differ (filled vs outlined) purely by call site.
      expect(_fillOf(tester, 'Gợi ý'), _fillOf(tester, 'Lọc'));
    });

    testWidgets('selection is what distinguishes a chip in $name', (
      tester,
    ) async {
      await _pump(tester, theme, [
        const SpendoChip(label: 'Tắt'),
        const SpendoChip(label: 'Bật', selected: true),
      ]);
      await tester.pumpAndSettle();

      expect(_fillOf(tester, 'Bật'), theme.colorScheme.primaryContainer);
      expect(_fillOf(tester, 'Tắt'), theme.colorScheme.surfaceContainer);
    });
  }

  testWidgets('a long label ellipsises instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(200, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, AppTheme.light(AppColorScheme.roseDefault), [
      const SpendoChip(label: 'Một danh mục có tên rất là dài không tưởng'),
    ]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a chip inside a Wrap hugs its label', (tester) async {
    await _pump(tester, AppTheme.light(AppColorScheme.roseDefault), [
      const SpendoChip(label: 'Ăn uống'),
      SpendoChip(label: 'Đi lại', onTap: () {}),
    ]);
    await tester.pumpAndSettle();

    // A Wrap hands each child a bounded max width; the chip used to grow to
    // all of it and land on a row of its own.
    final screen = tester.getSize(find.byType(Scaffold)).width;
    for (final label in ['Ăn uống', 'Đi lại']) {
      final width = tester.getSize(find.widgetWithText(SpendoChip, label)).width;
      expect(width, lessThan(screen / 3), reason: '$label must hug its text');
    }
    expect(
      tester.getTopLeft(find.widgetWithText(SpendoChip, 'Đi lại')).dy,
      tester.getTopLeft(find.widgetWithText(SpendoChip, 'Ăn uống')).dy,
      reason: 'two short chips share one row',
    );
  });

  group('pop on tap', () {
    double scaleOf(WidgetTester tester, String label) => tester
        .widget<AnimatedScale>(
          find.descendant(
            of: find.widgetWithText(SpendoChip, label),
            matching: find.byType(AnimatedScale),
          ).last, // the outer one belongs to PressableScale
        )
        .scale;

    testWidgets('a choice chip springs to 1.12 and settles back', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, AppTheme.light(AppColorScheme.roseDefault), [
        SpendoChip(label: 'Lọc', onTap: () => taps++),
      ]);
      await tester.pumpAndSettle();
      expect(scaleOf(tester, 'Lọc'), 1);

      await tester.tap(find.text('Lọc'));
      await tester.pump();
      expect(taps, 1);
      expect(scaleOf(tester, 'Lọc'), 1.12);

      await tester.pumpAndSettle();
      expect(scaleOf(tester, 'Lọc'), 1);
    });

    testWidgets('a meta chip does not pop', (tester) async {
      await _pump(tester, AppTheme.light(AppColorScheme.roseDefault), [
        SpendoChip.meta(label: 'Hôm nay', onTap: () {}),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hôm nay'));
      await tester.pump();
      expect(scaleOf(tester, 'Hôm nay'), 1);
    });

    testWidgets('reduce motion skips the pop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppColorScheme.roseDefault),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Wrap(children: [SpendoChip(label: 'Lọc', onTap: () {})]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lọc'));
      await tester.pump();
      expect(scaleOf(tester, 'Lọc'), 1);
    });
  });
}
