import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/onboarding/presentation/onboarding_prefs.dart';
import 'package:spendo/shared/widgets/splash_screen.dart';

Widget _app({
  required InitCallback onInit,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      darkTheme: AppTheme.dark(AppColorScheme.roseDefault),
      themeMode: themeMode,
      home: SplashScreen(
        onInit: onInit,
        nextScreenBuilder: (_, completed) => Scaffold(
          body: Text(completed ? 'App ready' : 'Welcome'),
        ),
      ),
    ),
  );
}

/// Walks the entry animation, the 500ms settle and the exit fade.
Future<void> _runThroughSplash(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Spendo',
      packageName: 'com.example.spendo',
      version: '1.7.12',
      buildNumber: '17',
      buildSignature: '',
    );
  });

  testWidgets('shows retry and only navigates after initialization succeeds', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      onboardingCompletedPrefsKey: true,
    });
    var attempts = 0;

    await tester.pumpWidget(
      _app(
        onInit: (_) async {
          attempts++;
          if (attempts == 1) throw StateError('database unavailable');
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(attempts, 1);
    expect(find.text('Không thể khởi động ứng dụng.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('App ready'), findsNothing);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();

    expect(attempts, 2);

    await tester.pumpAndSettle();

    expect(find.text('App ready'), findsOneWidget);
  });

  testWidgets('a first run lands on Welcome, a later one on the app', (
    tester,
  ) async {
    // Replaces StartupGate, which rendered a white Scaffold + spinner between
    // the two screens (`02-startup-gate.md` §J).
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_app(onInit: (_) async {}));
    await _runThroughSplash(tester);
    expect(find.text('Welcome'), findsOneWidget);
    // The gate's white spinner frame is gone.
    expect(find.byType(CircularProgressIndicator), findsNothing);

    SharedPreferences.setMockInitialValues({
      onboardingCompletedPrefsKey: true,
    });

    await tester.pumpWidget(_app(onInit: (_) async {}), duration: null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(onInit: (_) async {}));
    await _runThroughSplash(tester);
    expect(find.text('App ready'), findsOneWidget);
  });

  testWidgets('progress messages are in Vietnamese, like the rest of the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    // Held open by a completer, so init is still running when we look and
    // no stray timer outlives the test.
    final holdOpen = Completer<void>();

    await tester.pumpWidget(
      _app(
        onInit: (report) async {
          report(0.35, 'Đang mở dữ liệu…');
          await holdOpen.future;
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Đang mở dữ liệu…'), findsOneWidget);

    holdOpen.complete();
    await _runThroughSplash(tester);
  });

  testWidgets('it paints on the themed surface in dark mode', (tester) async {
    SharedPreferences.setMockInitialValues({
      onboardingCompletedPrefsKey: true,
    });

    final holdOpen = Completer<void>();

    await tester.pumpWidget(
      _app(onInit: (_) => holdOpen.future, themeMode: ThemeMode.dark),
    );
    await tester.pump(const Duration(milliseconds: 1200));

    // Phase 0 moved the splash onto the theme; this keeps it there.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final dark = AppTheme.dark(AppColorScheme.roseDefault);
    expect(scaffold.backgroundColor, dark.colorScheme.surface);

    holdOpen.complete();
    await _runThroughSplash(tester);
  });
}
