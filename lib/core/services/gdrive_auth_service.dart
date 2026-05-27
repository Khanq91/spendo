import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Handles Google Sign-In specifically for Google Drive backup.
/// Completely independent from Supabase Auth.
class GDriveAuthService {
  GDriveAuthService._();
  static final instance = GDriveAuthService._();

  final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  /// Try to restore previous sign-in session silently.
  Future<bool> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      return account != null;
    } catch (e) {
      debugPrint('[GDrive] Silent sign-in failed: $e');
      return false;
    }
  }

  /// Interactive sign-in with Google account picker.
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      debugPrint('[GDrive] Sign-in failed: $e');
      return false;
    }
  }

  /// Sign out from Google (does not revoke access).
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Whether the user is currently signed in.
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// The signed-in user's email.
  String? get currentEmail => _googleSignIn.currentUser?.email;

  /// Get a Drive API instance with authenticated headers.
  Future<drive.DriveApi?> getDriveApi() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;

    try {
      final headers = await account.authHeaders;
      final client = _GoogleAuthClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('[GDrive] Failed to get Drive API: $e');
      return null;
    }
  }
}

/// Simple HTTP client that adds Google auth headers to every request.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
