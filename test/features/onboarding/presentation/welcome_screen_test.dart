import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/core/theme/visual_mode_provider.dart';
import 'package:spendo/features/onboarding/presentation/onboarding_prefs.dart';
import 'package:spendo/features/onboarding/presentation/welcome_screen.dart';

Widget _app() {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      home: const WelcomeScreen(),
    ),
  );
}

/// The aurora background loops forever, so `pumpAndSettle` never returns on
/// this screen; the page transition is pumped by hand instead.
Future<void> _turnPage(WidgetTester tester) async {
  await tester.tap(find.text('Tiếp theo'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('page 1 introduces what the app actually does', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    // The old page 0 was one sentence over an empty bottom half
    // (`03-welcome.md` §L). The rows are rich text, so match the span.
    expect(find.textContaining('Ghi trong 5 giây'), findsOneWidget);
    expect(find.textContaining('Hạn mức & nhắc nhở'), findsOneWidget);
    expect(find.textContaining('Dữ liệu của bạn'), findsOneWidget);
  });

  testWidgets('there are two pages and the last one says Bắt đầu', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('Tiếp theo'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsNothing);

    await _turnPage(tester);

    // Page 2 folds the two old setup pages together.
    expect(find.text('ĐỒ HOẠ'), findsOneWidget);
    expect(find.text('SAO LƯU (TUỲ CHỌN)'), findsOneWidget);
    // The old flow said "Tiếp theo" even on the final step.
    expect(find.text('Bắt đầu'), findsOneWidget);
  });

  testWidgets('Bỏ qua is offered on every page, not only the last', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.text('Bỏ qua'), findsOneWidget);

    await _turnPage(tester);
    expect(find.text('Bỏ qua'), findsOneWidget);
  });

  testWidgets('skipping still records the graphics choice on the way out', (
    tester,
  ) async {
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              theme: AppTheme.light(AppColorScheme.roseDefault),
              home: WelcomeScreen(
                // The real destination reaches the notification plugin, which
                // a widget test has no binding for.
                destinationBuilder: (_) =>
                    const Scaffold(body: Text('App ready')),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    await _turnPage(tester);
    await tester.tap(find.text('Xịn xò'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Bỏ qua'));
    // Two pumps: one for the tap, one for the awaited writes. The push that
    // follows is allowed to fail; the assertions below are about what was
    // written first.
    await tester.pump();
    await tester.pump();
    expect(find.text('App ready'), findsOneWidget);

    // Leaving through "Bỏ qua" must not throw away the choice just made — the
    // old build only saved the mode when "Tiếp theo" moved off that page.
    expect(container.read(visualModeProvider), AppVisualMode.fancy);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(onboardingCompletedPrefsKey), isTrue);
  });

  testWidgets('the dots track the current page', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    // Two dots, one wide (current) and one small.
    Iterable<double> dotWidths() => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => c.constraints?.maxWidth ?? 0)
        .where((w) => w == 8 || w == 20);

    expect(dotWidths().length, 2);
    expect(dotWidths().where((w) => w == 20).length, 1);
  });

  testWidgets('both pages fit a 360×640 screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pump();
    expect(tester.takeException(), isNull);

    await _turnPage(tester);
    expect(tester.takeException(), isNull);
  });
}
