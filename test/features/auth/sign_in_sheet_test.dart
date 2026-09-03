import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/theme/app_theme.dart';
import 'package:spendo/features/auth/presentation/providers/auth_provider.dart';
import 'package:spendo/features/auth/presentation/widgets/sign_in_sheet.dart';
import 'package:spendo/shared/widgets/notice/notice.dart';
import 'package:spendo/shared/widgets/spendo/spendo.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

/// Records what the sheet asked for; answers as told.
class _FakeAuth implements AuthActions {
  final calls = <String>[];
  Object? failWith;
  bool signUpReady = true;

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn:$email:$password');
    if (failWith != null) throw failWith!;
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    calls.add('signUp:$email:$password');
    if (failWith != null) throw failWith!;
    return signUpReady;
  }

  @override
  Future<void> signOut() async => calls.add('signOut');
}

Future<_FakeAuth> _open(WidgetTester tester) async {
  final auth = _FakeAuth();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authActionsProvider.overrideWithValue(auth)],
      child: MaterialApp(
        theme: AppTheme.light(AppColorScheme.roseDefault),
        builder: (_, child) => NoticeHost(child: child ?? const SizedBox()),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSignInSheet(context),
              child: const Text('Mở'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  setUp(AppNotice.reset);

  testWidgets('opens on sign-in and flips to sign-up', (tester) async {
    await _open(tester);

    expect(find.text('Đăng nhập'), findsNWidgets(2)); // title + button
    expect(find.text('Chưa có tài khoản? Đăng ký'), findsOneWidget);

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản'), findsNWidgets(2));
    expect(find.text('Đã có tài khoản? Đăng nhập'), findsOneWidget);
  });

  testWidgets('validates the fields inline before calling the server', (
    tester,
  ) async {
    final auth = await _open(tester);

    await tester.tap(find.byType(SpendoButton));
    await tester.pumpAndSettle();

    expect(find.text('Nhập email hợp lệ'), findsOneWidget);
    expect(auth.calls, isEmpty);

    await tester.enterText(find.byKey(const ValueKey('auth_email')), 'an@x.vn');
    await tester.enterText(find.byKey(const ValueKey('auth_password')), '123');
    await tester.tap(find.byType(SpendoButton));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu ít nhất 6 ký tự'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('a good sign-in calls through, closes and says so', (
    tester,
  ) async {
    final auth = await _open(tester);

    await tester.enterText(find.byKey(const ValueKey('auth_email')), 'an@x.vn');
    await tester.enterText(
      find.byKey(const ValueKey('auth_password')),
      'secret1',
    );
    await tester.tap(find.byType(SpendoButton));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signIn:an@x.vn:secret1']);
    expect(find.byType(SignInSheet), findsNothing);
    expect(find.text('Đã đăng nhập.'), findsOneWidget);
  });

  testWidgets('a server refusal stays on the sheet, in plain words', (
    tester,
  ) async {
    final auth = await _open(tester);
    auth.failWith = const AuthException('Invalid login credentials');

    await tester.enterText(find.byKey(const ValueKey('auth_email')), 'an@x.vn');
    await tester.enterText(
      find.byKey(const ValueKey('auth_password')),
      'secret1',
    );
    await tester.tap(find.byType(SpendoButton));
    await tester.pumpAndSettle();

    expect(find.byType(SignInSheet), findsOneWidget);
    expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
  });

  testWidgets('a sign-up that needs confirmation says to check the inbox', (
    tester,
  ) async {
    final auth = await _open(tester);
    auth.signUpReady = false;

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('auth_email')), 'an@x.vn');
    await tester.enterText(
      find.byKey(const ValueKey('auth_password')),
      'secret1',
    );
    await tester.tap(find.byType(SpendoButton));
    await tester.pumpAndSettle();

    expect(auth.calls, ['signUp:an@x.vn:secret1']);
    expect(find.textContaining('email xác nhận'), findsOneWidget);
  });
}
