import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/services/reset_data_service.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/settings/presentation/screens/reset_data_confirm_screen.dart';
import 'package:spendo/features/settings/presentation/screens/reset_data_screen.dart';
import 'package:spendo/features/settings/presentation/widgets/hold_to_delete_button.dart';

const _summary = ResetDataSummary(
  transactions: 12,
  wallets: 3,
  loans: 2,
  reminders: 4,
  customCategories: 5,
  budgets: 6,
);

/// Records what the reset flow did instead of touching plugins.
class _Recorder {
  int runs = 0;
  int completions = 0;

  Future<void> _noop() async {}

  ResetDataService get service => ResetDataService(
    cancelBackgroundTasks: _noop,
    cancelNotifications: _noop,
    signOutDrive: _noop,
    clearDatabase: () async => runs++,
    clearPreferences: _noop,
    clearTemporaryFiles: _noop,
    syncWidgets: _noop,
  );
}

/// Both screens under a real router, so `push` and `pop` behave as in the app.
Widget _app(_Recorder recorder, {String initialLocation = '/settings/reset'}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, __) => const Scaffold(body: Text('hub')),
      ),
      GoRoute(
        path: '/settings/reset',
        builder: (_, __) => const ResetDataScreen(),
      ),
      GoRoute(
        path: '/settings/reset/confirm',
        builder: (_, __) => ResetDataConfirmScreen(
          service: recorder.service,
          loadSummary: () async => _summary,
          onCompleted: (_) => recorder.completions++,
        ),
      ),
    ],
  );

  return ProviderScope(
    child: MaterialApp.router(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ResetDataScreen', () {
    testWidgets('explains, warns, and only then opens the confirmation', (
      tester,
    ) async {
      final recorder = _Recorder();
      await tester.pumpWidget(_app(recorder));
      await tester.pumpAndSettle();

      expect(find.text('Đặt lại dữ liệu'), findsOneWidget);
      expect(find.text('Vùng nguy hiểm'), findsOneWidget);
      expect(find.text('Xóa toàn bộ dữ liệu'), findsOneWidget);
      expect(find.byType(ResetDataConfirmScreen), findsNothing);

      await tester.tap(find.text('Xóa toàn bộ dữ liệu'));
      // Settles the page transition and the confirm screen's countdown.
      await tester.pumpAndSettle();

      expect(find.byType(ResetDataConfirmScreen), findsOneWidget);
      expect(recorder.runs, 0);
    });
  });

  group('ResetDataConfirmScreen', () {
    Future<void> open(WidgetTester tester, _Recorder recorder) async {
      // Tall enough for the whole list plus the pinned footer.
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(recorder, initialLocation: '/settings/reset/confirm'),
      );
      // The summary future and the first countdown frame.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
    }

    testWidgets('lists what will be lost with the live counts', (
      tester,
    ) async {
      final recorder = _Recorder();
      await open(tester, recorder);

      expect(find.text('NHỮNG GÌ SẼ MẤT'), findsOneWidget);
      for (final (label, count) in [
        ('Giao dịch', '12'),
        ('Nguồn tiền', '3'),
        ('Khoản vay & sổ theo dõi', '2'),
        ('Nhắc nhở', '4'),
        ('Danh mục tự tạo', '5'),
        ('Ngân sách', '6'),
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
        expect(find.text(count), findsOneWidget, reason: '$label = $count');
      }
      expect(find.text('Đăng nhập Google Drive'), findsOneWidget);
      expect(find.text('Xuất bản sao lưu trước'), findsOneWidget);
    });

    testWidgets('XÓA counts down 10s and ignores presses until then', (
      tester,
    ) async {
      final recorder = _Recorder();
      await open(tester, recorder);

      expect(find.text(HoldToDeleteButton.countdownLabel(10)), findsOneWidget);
      expect(find.text(HoldToDeleteButton.armedLabel), findsNothing);

      // A 4s hold during the countdown does nothing.
      final button = find.byType(HoldToDeleteButton);
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(seconds: 4));
      await gesture.up();
      await tester.pump();
      expect(recorder.runs, 0);
      expect(find.text(HoldToDeleteButton.countdownLabel(6)), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      expect(find.text(HoldToDeleteButton.armedLabel), findsOneWidget);
    });

    testWidgets('once armed, a short hold snaps back and a 3s hold resets', (
      tester,
    ) async {
      final recorder = _Recorder();
      await open(tester, recorder);
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      expect(find.text(HoldToDeleteButton.armedLabel), findsOneWidget);

      final button = find.byType(HoldToDeleteButton);

      // In flutter_test an animation's clock starts on the first frame after
      // it is scheduled, so each hold pumps one frame before the held time.

      // Released after 1s: nothing happens.
      var gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(recorder.runs, 0);
      expect(recorder.completions, 0);

      // Held for the full 3s: the reset runs once and the app restarts.
      gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump();
      expect(recorder.runs, 1);
      expect(recorder.completions, 1);
    });

    testWidgets('Hủy leaves without touching anything', (tester) async {
      final recorder = _Recorder();
      await tester.pumpWidget(_app(recorder));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa toàn bộ dữ liệu'));
      await tester.pumpAndSettle();
      expect(find.byType(ResetDataConfirmScreen), findsOneWidget);

      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(find.byType(ResetDataConfirmScreen), findsNothing);
      expect(find.byType(ResetDataScreen), findsOneWidget);
      expect(recorder.runs, 0);
    });
  });
}
