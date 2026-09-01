import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/shared/domain/period.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';

Future<Period?> _open(WidgetTester tester, Period selected) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Period? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await PeriodPickerSheet.show(
                context: context,
                selected: selected,
              );
            },
            child: const Text('Mở'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('picking a month returns that whole month', (tester) async {
    final now = DateTime.now();
    await _open(tester, Period.month(DateTime(now.year, now.month)));

    // Both pickers the audit found are now one sheet: a month grid...
    expect(find.text('Th.1'), findsOneWidget);
    expect(find.text('Th.12'), findsOneWidget);
    // ...plus the presets the grid cannot express.
    expect(find.text('3 tháng gần nhất'), findsOneWidget);
    expect(find.text('Năm nay'), findsOneWidget);

    await tester.tap(find.text('Th.1'));
    await tester.pumpAndSettle();

    expect(find.text('Th.1'), findsNothing, reason: 'sheet should close');
  });

  testWidgets('future months in the current year are not selectable', (
    tester,
  ) async {
    final now = DateTime.now();
    if (now.month == 12) return; // No future month to assert on in December.

    await _open(tester, Period.month(DateTime(now.year, now.month)));

    final futureLabel = 'Th.${now.month + 1}';
    await tester.tap(find.text(futureLabel));
    await tester.pumpAndSettle();

    // The sheet stays open: a future month cannot be chosen.
    expect(find.text('Th.1'), findsOneWidget);
  });

  testWidgets('the year stepper stops at today and three years back', (
    tester,
  ) async {
    final now = DateTime.now();
    await _open(tester, Period.month(DateTime(now.year, now.month)));

    expect(find.text('${now.year}'), findsOneWidget);

    // Forward is already at the limit.
    await tester.tap(find.byTooltip('Năm sau'));
    await tester.pumpAndSettle();
    expect(find.text('${now.year}'), findsOneWidget);

    await tester.tap(find.byTooltip('Năm trước'));
    await tester.pumpAndSettle();
    expect(find.text('${now.year - 1}'), findsOneWidget);
  });

  testWidgets('the preset matching the current selection reads as selected', (
    tester,
  ) async {
    await _open(tester, PeriodPreset.lastThreeMonths.resolve());

    final chip = tester.widget<SpendoChip>(
      find.widgetWithText(SpendoChip, '3 tháng gần nhất'),
    );
    expect(chip.selected, isTrue);

    final other = tester.widget<SpendoChip>(
      find.widgetWithText(SpendoChip, 'Năm nay'),
    );
    expect(other.selected, isFalse);
  });

  testWidgets('the custom range option can be hidden', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        home: Scaffold(
          body: PeriodPickerSheet(
            selected: Period.month(DateTime.now()),
            allowCustomRange: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('period_custom_range')), findsNothing);

    // Month-only screens keep the presets that resolve to a whole month...
    expect(find.text('Tháng này'), findsOneWidget);
    expect(find.text('Tháng trước'), findsOneWidget);
    // ...and drop the ones they could not honour, rather than offering an
    // option that would be silently coerced.
    expect(find.text('3 tháng gần nhất'), findsNothing);
    expect(find.text('Năm nay'), findsNothing);
  });
}
