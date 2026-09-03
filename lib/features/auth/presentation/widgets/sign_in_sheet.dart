import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/notice/notice.dart';
import '../../../../shared/widgets/spendo/spendo.dart';
import '../providers/auth_provider.dart';

/// Opens the sign-in / sign-up sheet. The single place it is presented.
Future<void> showSignInSheet(BuildContext context) {
  return SpendoSheet.showModal<void>(
    context: context,
    builder: (_) => const SignInSheet(),
  );
}

/// Email + password for the Spendo account behind `AppConfig.cloudEnabled`.
///
/// One sheet for both directions: it opens on Đăng nhập, and a line under
/// the button flips it to Tạo tài khoản. Field errors are inline; a server
/// error goes on one line above the button, in the words of
/// [authErrorMessage].
class SignInSheet extends ConsumerStatefulWidget {
  const SignInSheet({super.key});

  @override
  ConsumerState<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends ConsumerState<SignInSheet> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _register = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _flip() => setState(() {
    _register = !_register;
    _formError = null;
  });

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    setState(() {
      _emailError = email.contains('@') && email.contains('.')
          ? null
          : 'Nhập email hợp lệ';
      _passwordError = password.length >= 6 ? null : 'Mật khẩu ít nhất 6 ký tự';
      _formError = null;
    });
    if (_emailError != null) {
      _emailFocus.requestFocus();
      return;
    }
    if (_passwordError != null) {
      _passwordFocus.requestFocus();
      return;
    }

    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final actions = ref.read(authActionsProvider);

    try {
      if (_register) {
        final ready = await actions.signUp(email: email, password: password);
        if (!mounted) return;
        navigator.pop();
        if (ready) {
          AppNotice.success('Đã tạo tài khoản và đăng nhập.');
        } else {
          AppNotice.info(
            'Đã gửi email xác nhận tới $email. Xác nhận xong thì đăng nhập.',
          );
        }
      } else {
        await actions.signIn(email: email, password: password);
        if (!mounted) return;
        navigator.pop();
        AppNotice.success('Đã đăng nhập.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _formError = authErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SpendoSheet(
      header: SpendoSheetHeader(
        title: _register ? 'Tạo tài khoản' : 'Đăng nhập',
        onCancel: _busy ? null : () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tài khoản Spendo đồng bộ dữ liệu giữa các máy và mở liên kết '
              'ngân hàng tự động.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('auth_email'),
              controller: _emailCtrl,
              focusNode: _emailFocus,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _emailError,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('auth_password'),
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              enabled: !_busy,
              obscureText: !_showPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                errorText: _passwordError,
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 10),
              Text(
                _formError!,
                key: const ValueKey('auth_form_error'),
                style: TextStyle(fontSize: 12.5, color: cs.error),
              ),
            ],
            const SizedBox(height: 16),
            SpendoButton(
              label: _register ? 'Tạo tài khoản' : 'Đăng nhập',
              expand: true,
              busy: _busy,
              onPressed: _busy ? null : _submit,
            ),
            const SizedBox(height: 4),
            Semantics(
              button: true,
              child: InkWell(
                onTap: _busy ? null : _flip,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _register
                        ? 'Đã có tài khoản? Đăng nhập'
                        : 'Chưa có tài khoản? Đăng ký',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
