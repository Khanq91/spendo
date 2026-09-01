import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/core/theme/theme_provider.dart';
import 'package:spendo/features/settings/presentation/screens/appearance_screen.dart';

/// Mirrors how the real app is wired: the page changes the providers and the
/// surrounding MaterialApp rebuilds, which is what makes the preview live.
class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: ref.watch(lightThemeProvider),
      darkTheme: ref.watch(darkThemeProvider),
      themeMode: ref.watch(themeModeProvider),
      home: const AppearanceScreen(),
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('all three choices live on one page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: _Host()));
    await tester.pumpAndSettle();

    // Mode, colour and graphics used to be 3 ListTiles plus 2 bottom sheets
    // (`27-visual-mode-and-theme-color-sheets.md` §L).
    for (final label in ['CHẾ ĐỘ', 'MÀU CHỦ ĐẠO', 'ĐỒ HOẠ', 'XEM TRƯỚC']) {
      expect(find.text(label), findsOneWidget);
    }
    for (final mode in ['Hệ thống', 'Sáng', 'Tối']) {
      expect(find.text(mode), findsOneWidget);
    }
    for (final scheme in AppColorScheme.values) {
      expect(find.text(scheme.label), findsOneWidget);
    }
    expect(find.text('Bình thường'), findsOneWidget);
    expect(find.text('Xịn xò'), findsOneWidget);
  });

  testWidgets('picking a mode applies it without leaving the page', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: _Host()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    // Still on the page — the old sheets popped on every choice.
    expect(find.text('Giao diện'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('XEM TRƯỚC'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('picking a colour repaints the preview', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: _Host()));
    await tester.pumpAndSettle();

    Color primary() =>
        Theme.of(tester.element(find.text('XEM TRƯỚC'))).colorScheme.primary;

    final before = primary();
    await tester.tap(find.text(AppColorScheme.emeraldWealth.label));
    await tester.pumpAndSettle();

    expect(primary(), isNot(before));
  });

  testWidgets('picking a graphics mode keeps the page open', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: _Host()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xịn xò'));
    await tester.pumpAndSettle();

    expect(find.text('Giao diện'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the page fits a 360×640 screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: _Host()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
