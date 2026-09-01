import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/settings/presentation/providers/gdrive_provider.dart';
import 'package:spendo/features/settings/presentation/screens/backup_screen.dart';

/// Stands in for the real notifier so the page can be driven without touching
/// Google sign-in or WorkManager.
class _FakeGDrive extends StateNotifier<GDriveState> implements GDriveNotifier {
  _FakeGDrive(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(GDriveState state) {
  return ProviderScope(
    overrides: [gdriveProvider.overrideWith((ref) => _FakeGDrive(state))],
    child: MaterialApp(
      theme: AppTheme.light(AppColorScheme.roseDefault),
      home: const BackupScreen(),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Drive, local files and CSV live on one page', (tester) async {
    await tester.pumpWidget(_app(const GDriveState()));
    await tester.pumpAndSettle();

    // Three separate Settings sections in the old screen.
    expect(find.text('GOOGLE DRIVE'), findsOneWidget);
    expect(find.text('FILE CỤC BỘ & BÁO CÁO'), findsOneWidget);
    expect(find.text('Xuất backup JSON'), findsOneWidget);
    expect(find.text('Nhập từ file backup'), findsOneWidget);
    expect(find.text('Xuất báo cáo CSV'), findsOneWidget);
  });

  testWidgets('signed out, the status card says so and offers sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const GDriveState()));
    await tester.pumpAndSettle();

    expect(find.text('Chưa bật sao lưu'), findsOneWidget);
    expect(find.text('Kết nối Google Drive'), findsOneWidget);
  });

  testWidgets('signed in with no backup yet, the card names the next step', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const GDriveState(isSignedIn: true, email: 'an.nguyen@gmail.com')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có bản sao lưu nào'), findsOneWidget);
    expect(
      find.text('Chạy "Sao lưu ngay" để tạo bản đầu tiên'),
      findsOneWidget,
    );
  });

  testWidgets('a recent backup reads as safe, with a relative timestamp', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        GDriveState(
          isSignedIn: true,
          email: 'an.nguyen@gmail.com',
          lastBackupTime: DateTime.now().subtract(const Duration(hours: 2)),
          frequency: BackupFrequency.daily,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã sao lưu an toàn'), findsOneWidget);
    expect(find.textContaining('2 giờ trước'), findsOneWidget);
  });

  testWidgets('signed in, the page offers the four Drive actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const GDriveState(
          isSignedIn: true,
          email: 'an.nguyen@gmail.com',
          frequency: BackupFrequency.daily,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('an.nguyen@gmail.com'), findsOneWidget);
    expect(find.text('Tự động sao lưu'), findsOneWidget);
    expect(find.text('Hàng ngày'), findsOneWidget);
    expect(find.text('Sao lưu ngay'), findsOneWidget);
    expect(find.text('Khôi phục từ Drive'), findsOneWidget);
  });

  testWidgets('the page fits a 360×640 screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(const GDriveState(isSignedIn: true, email: 'a@b.com')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
