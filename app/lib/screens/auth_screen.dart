import 'package:flutter/material.dart';

import '../core/models/user_snapshot.dart';
import '../core/repositories/user_repository.dart';
import '../core/services/api_client.dart';
import '../core/services/storage_service.dart';
import '../ui/contracts/skin_scope.dart';

/// Login + sign-up screen. Shown when the snapshot endpoint returns 401 (no
/// stored token, or the token is invalid).
///
/// Kept deliberately calm and compact: a neutral wordmark, one accent colour
/// (the button + links), subtle field borders, and plain-text status lines.
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
  // One soft red for errors — the only colour on the page besides the accent.
  static const _errorColor = Color(0xFFFF6B81);

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

    return DecoratedBox(
      // Exact same gradient as the launch screen (LaunchScreen.storyboard):
      // 40 dark indigo → dark purple steps, top to bottom.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C0420), Color(0xFF0D0421), Color(0xFF0F0522),
            Color(0xFF110522), Color(0xFF120523), Color(0xFF140524),
            Color(0xFF160624), Color(0xFF170625), Color(0xFF190626),
            Color(0xFF1B0626), Color(0xFF1C0727), Color(0xFF1E0728),
            Color(0xFF200728), Color(0xFF210729), Color(0xFF23082A),
            Color(0xFF25082A), Color(0xFF26082B), Color(0xFF28082C),
            Color(0xFF2A092C), Color(0xFF2B092D), Color(0xFF2D092E),
            Color(0xFF2E092F), Color(0xFF300A2F), Color(0xFF320A30),
            Color(0xFF330A31), Color(0xFF350A31), Color(0xFF370B32),
            Color(0xFF380B33), Color(0xFF3A0B33), Color(0xFF3C0B34),
            Color(0xFF3D0C35), Color(0xFF3F0C35), Color(0xFF410C36),
            Color(0xFF420C37), Color(0xFF440D37), Color(0xFF460D38),
            Color(0xFF470D39), Color(0xFF490D39), Color(0xFF4B0E3A),
            Color(0xFF4C0E3B),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'XPULSE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin ? 'Welcome back' : 'Create your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  if (!_isLogin) ...[
                    _Field(controller: _displayName, hint: 'Name'),
                    const SizedBox(height: 10),
                  ],
                  _Field(
                    controller: _email,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    controller: _password,
                    hint: 'Password',
                    obscureText: true,
                  ),
                  if (_error != null || _info != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error ?? _info!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _error != null ? _errorColor : p.textMuted,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  _PrimaryButton(
                    label: _isLogin ? 'Log in' : 'Sign up',
                    busy: _busy,
                    onTap: _busy ? null : _submit,
                    color: p.accent,
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _busy ? null : _toggleMode,
                    behavior: HitTestBehavior.opaque,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? "New here?  "
                                : 'Already have an account?  ',
                            style: TextStyle(
                              color: p.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: _isLogin ? 'Sign up' : 'Log in',
                            style: TextStyle(
                              color: p.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single filled input with a subtle hairline border. Placeholder-only —
/// no uppercase label above — to keep the form compact.
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  const _Field({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autocorrect: false,
        enableSuggestions: false,
        style: TextStyle(color: p.textPrimary, fontSize: 15),
        cursorColor: p.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: p.textMuted.withValues(alpha: 0.6),
            fontSize: 15,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

/// Solid single-colour primary action. No border, no glow.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onTap;
  final Color color;
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: busy ? color.withValues(alpha: 0.5) : color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
