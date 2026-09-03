import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('authErrorMessage', () {
    test('turns the common Supabase answers into a next step', () {
      expect(
        authErrorMessage(const AuthException('Invalid login credentials')),
        'Email hoặc mật khẩu không đúng.',
      );
      expect(
        authErrorMessage(const AuthException('User already registered')),
        contains('đã có tài khoản'),
      );
      expect(
        authErrorMessage(const AuthException('Email not confirmed')),
        contains('xác nhận'),
      );
      expect(
        authErrorMessage(
          const AuthException('Password should be at least 6 characters'),
        ),
        contains('6 ký tự'),
      );
    });

    test('passes an unknown auth message through as it came', () {
      expect(
        authErrorMessage(const AuthException('Signups not allowed')),
        'Signups not allowed',
      );
    });

    test('anything else reads as a connection problem', () {
      expect(authErrorMessage(StateError('socket')), contains('máy chủ'));
    });
  });

  test('SpendoAccount.fromSession is null-safe', () {
    expect(SpendoAccount.fromSession(null), isNull);
  });
}
