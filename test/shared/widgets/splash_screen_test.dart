import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spendo/shared/widgets/splash_screen.dart';

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
    var attempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SplashScreen(
            onInit: (_) async {
              attempts++;
              if (attempts == 1) {
                throw StateError('database unavailable');
              }
            },
            nextScreen: const Scaffold(body: Text('App ready')),
          ),
        ),
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
}
