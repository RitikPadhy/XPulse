import 'package:flutter/material.dart';

import '../core/models/user_snapshot.dart';
import '../core/repositories/user_repository.dart';
import '../core/services/api_client.dart';
import '../core/services/storage_service.dart';
import '../ui/contracts/skin_scope.dart';

/// Login + sign-up screen. Shown when the snapshot endpoint returns 401 (no
/// stored token, or the token is invalid).
class AuthScreen extends StatefulWidget {
  /// Invoked after a successful login/signup with the freshly-fetched
  /// snapshot — so the host renders Home directly, no BOOTING gap.
  final void Function(UserSnapshot snapshot) onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum _Mode { login, signup }

class _AuthScreenState extends State<AuthScreen> {
  _Mode _mode = _Mode.login;
  bool _busy = false;
  String? _error;
  String? _info;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();

  bool get _isLogin => _mode == _Mode.login;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _mode = _isLogin ? _Mode.signup : _Mode.login;
      _error = null;
      _info = null;
    });
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pwd = _password.text;
    final name = _displayName.text.trim();

    if (email.isEmpty || pwd.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    if (!_isLogin && name.isEmpty) {
      setState(() => _error = 'Pick a display name.');
      return;
    }
    if (!_isLogin && pwd.length < 8) {
      setState(() => _error = 'Password needs at least 8 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    try {
      final api = ApiClient();
      if (_isLogin) {
        final result = await api.login(email: email, password: pwd);
        await StorageService.instance.setApiToken(result.token);
        // Fetch the snapshot here so AppShell can render Home immediately on
        // the next frame — no intermediate loading screen.
        final snapshot = await UserRepository().loadCurrent();
        if (!mounted) return;
        widget.onAuthenticated(snapshot);
      } else {
        // Sign-up creates the account but does NOT log the user in. Drop them
        // on the login page to sign in with their new credentials.
        await api.signup(email: email, password: pwd, displayName: name);
        if (!mounted) return;
        setState(() {
          _mode = _Mode.login;
          _busy = false;
          _password.clear();
          _displayName.clear();
          _error = null;
          _info = 'Account created — log in to continue.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;

    // Opaque gradient sky so the skin's animated scene (retro sun, grid floor)
    // doesn't bleed through — keeps the synthwave mood without a flat-black
    // (or busy) backdrop behind the form.
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B0420), Color(0xFF3A0E3D)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  'XPULSE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.primary,
                    fontFamily: 'Courier',
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'LOG IN' : 'SIGN UP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.accent,
                    fontFamily: 'Courier',
                    fontSize: 14,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 36),
                if (!_isLogin) ...[
                  _PixelField(
                    controller: _displayName,
                    label: 'NAME',
                    hint: 'your name',
                  ),
                  const SizedBox(height: 12),
                ],
                _PixelField(
                  controller: _email,
                  label: 'EMAIL',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _PixelField(
                  controller: _password,
                  label: 'PASSWORD',
                  hint: _isLogin ? 'enter password' : '8+ characters',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: 0.12),
                      border: Border.all(color: p.primary, width: 1.5),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: p.primary,
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_info != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.12),
                      border: Border.all(color: p.accent, width: 1.5),
                    ),
                    child: Text(
                      _info!,
                      style: TextStyle(
                        color: p.accent,
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                GestureDetector(
                  onTap: _busy ? null : _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _busy
                          ? p.primary.withValues(alpha: 0.4)
                          : p.primary,
                      border: Border.all(color: p.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: p.primary.withValues(alpha: 0.55),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Text(
                      _busy ? '...' : (_isLogin ? 'LOG IN' : 'SIGN UP'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: _busy ? null : _toggleMode,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? 'NEW USER?  '
                                : 'ALREADY A USER?  ',
                            style: TextStyle(
                              color: p.textMuted,
                              fontFamily: 'Courier',
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          TextSpan(
                            text: _isLogin ? 'SIGN UP' : 'LOG IN',
                            style: TextStyle(
                              color: p.accent,
                              fontFamily: 'Courier',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  const _PixelField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: p.textMuted,
            fontFamily: 'Courier',
            fontSize: 11,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.accent, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            autocorrect: false,
            enableSuggestions: false,
            style: TextStyle(
              color: p.textPrimary,
              fontFamily: 'Courier',
              fontSize: 16,
              letterSpacing: 1,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: p.textMuted.withValues(alpha: 0.5),
                fontFamily: 'Courier',
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
