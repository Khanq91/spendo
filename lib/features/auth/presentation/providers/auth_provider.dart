import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config.dart';

/// Whether the cloud side of the app is switched on — see
/// [AppConfig.cloudEnabled]. A provider rather than the bare const so a test
/// can flip it; at runtime it is the const.
final cloudEnabledProvider = Provider<bool>((_) => AppConfig.cloudEnabled);

/// The signed-in Spendo account, or null.
///
/// Stays null while the cloud is off — without touching `Supabase.instance`,
/// which is not initialised then. Pages that depend on a session watch this;
/// tests override it with a fixed [SpendoAccount].
final authUserProvider = StreamProvider<SpendoAccount?>((ref) {
  if (!ref.watch(cloudEnabledProvider)) return Stream.value(null);
  return _sessions(Supabase.instance.client.auth).map(SpendoAccount.fromSession);
});

/// Current session first, then every change after it.
Stream<Session?> _sessions(GoTrueClient auth) async* {
  yield auth.currentSession;
  yield* auth.onAuthStateChange.map((event) => event.session);
}

/// What the UI needs to know about the account: enough to greet and to
/// scope, nothing else from the Supabase user object.
class SpendoAccount {
  const SpendoAccount({required this.id, this.email});

  final String id;
  final String? email;

  static SpendoAccount? fromSession(Session? session) => session == null
      ? null
      : SpendoAccount(id: session.user.id, email: session.user.email);
}

/// Sign in, sign up, sign out — behind an interface so the sheet can be
/// driven in tests without a server.
abstract class AuthActions {
  Future<void> signIn({required String email, required String password});

  /// True when the account is usable straight away; false when the server
  /// sent a confirmation email first and the user has to come back.
  Future<bool> signUp({required String email, required String password});

  Future<void> signOut();
}

final authActionsProvider = Provider<AuthActions>(
  (_) => const SupabaseAuthActions(),
);

class SupabaseAuthActions implements AuthActions {
  const SupabaseAuthActions();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    final response = await _auth.signUp(email: email, password: password);
    return response.session != null;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// The one line the sheet shows for a failed sign-in or sign-up.
///
/// Supabase answers in English; the common cases get a Vietnamese sentence
/// that says what to do next, anything else falls back to the server's text,
/// and a non-auth error (no network, most likely) gets the generic line.
String authErrorMessage(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return 'Email này đã có tài khoản — đăng nhập thay vì đăng ký.';
    }
    if (message.contains('email not confirmed')) {
      return 'Email chưa được xác nhận. Kiểm tra hộp thư rồi thử lại.';
    }
    if (message.contains('password should be')) {
      return 'Mật khẩu cần ít nhất 6 ký tự.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Thử quá nhiều lần. Đợi vài phút rồi thử lại.';
    }
    return error.message;
  }
  return 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';
}
