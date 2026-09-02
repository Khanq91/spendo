import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/shared/widgets/notice/notice.dart';

const _hidden = Offset(0, -1.6);

Widget _app() => MaterialApp(
  theme: AppTheme.light(AppColorScheme.roseDefault),
  builder: (_, child) => NoticeHost(child: child ?? const SizedBox()),
  home: const Scaffold(body: SizedBox.expand()),
);

Offset _slideOf(WidgetTester tester) => tester
    .widget<AnimatedSlide>(
      find.descendant(
        of: find.byType(NoticeSlideIn),
        matching: find.byType(AnimatedSlide),
      ),
    )
    .offset;

Color _dotOf(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(NoticeSlideIn),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .firstWhere((decoration) => decoration.shape == BoxShape.circle)
    .color!;

void main() {
  setUp(AppNotice.reset);

  testWidgets('a request drops the banner in and it leaves on its own', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(_slideOf(tester), _hidden);

    AppNotice.success('Đã kết nối Google Drive.');
    await tester.pump();
    expect(find.text('Đã kết nối Google Drive.'), findsOneWidget);
    expect(_slideOf(tester), Offset.zero);

    // Success stays 2.2s, then the same bezier carries it back out.
    await tester.pump(const Duration(milliseconds: 2100));
    expect(_slideOf(tester), Offset.zero);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_slideOf(tester), _hidden);
    await tester.pumpAndSettle();
  });

  testWidgets('the dot takes the colour of the kind', (tester) async {
    await tester.pumpWidget(_app());
    final context = tester.element(find.byType(NoticeHost));

    for (final kind in NoticeKind.values) {
      AppNotice.show('Thông báo', kind: kind);
      await tester.pump();
      expect(
        _dotOf(tester),
        NoticeHost.dotColorFor(context, kind),
        reason: '$kind dot',
      );
    }
    await tester.pumpAndSettle();
  });

  testWidgets('an undo notice runs its action and dismisses on tap', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    var undone = false;
    AppNotice.undo('Đã xoá 120.000 ₫', onUndo: () => undone = true);
    await tester.pump();
    expect(find.text('Hoàn tác'), findsOneWidget);

    // Undo keeps the SnackBar's 5s, well past the 2.2s of a plain notice.
    await tester.pump(const Duration(seconds: 4));
    expect(_slideOf(tester), Offset.zero);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pump();
    expect(undone, isTrue);
    expect(_slideOf(tester), _hidden);
    await tester.pumpAndSettle();
  });

  testWidgets('a second request swaps the text and restarts the clock', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    AppNotice.info('Một');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));

    AppNotice.info('Hai');
    await tester.pump();
    expect(find.text('Hai'), findsOneWidget);
    expect(find.text('Một'), findsNothing);
    // Still on screen: the pill does not replay its drop for a retrigger.
    expect(_slideOf(tester), Offset.zero);

    // 1.5s after the swap the original 2.2s would have expired; the clock
    // restarted, so the banner is still up.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(_slideOf(tester), Offset.zero);
    await tester.pump(const Duration(milliseconds: 800));
    expect(_slideOf(tester), _hidden);
    await tester.pumpAndSettle();
  });

  testWidgets('the banner shows over a modal sheet', (tester) async {
    await tester.pumpWidget(_app());
    final context = tester.element(find.byType(Scaffold));
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SizedBox(height: 300),
    );
    await tester.pumpAndSettle();

    AppNotice.error('Không lưu được giao dịch. Thử lại.');
    await tester.pump();
    // The host sits above the navigator, so the banner is hit-testable
    // rather than buried under the sheet's barrier.
    expect(find.text('Không lưu được giao dịch. Thử lại.'), findsOneWidget);
    final banner = tester.getTopLeft(find.byType(NoticeSlideIn));
    expect(banner.dy, lessThan(100));
    await tester.pumpAndSettle();
  });
}
