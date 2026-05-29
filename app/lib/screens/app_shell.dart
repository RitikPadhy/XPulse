import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/models/user_snapshot.dart';
import '../core/repositories/user_repository.dart';
import '../core/services/api_client.dart';
import '../core/services/background_sync.dart';
import '../core/services/health_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/sync_service.dart';
import '../ui/contracts/skin_scope.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'side_quests_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Native side keeps the launch screen on top until we call "remove".
  static const _splashChannel = MethodChannel('xpulse/splash');

  UserSnapshot? _snapshot;
  Object? _error;
  bool _loading = true;
  bool _retrying = false;

  final _controller = PageController(initialPage: 1);
  final _storage = StorageService.instance;
  final _health = HealthService();
  late final _sync = SyncService(health: _health, storage: _storage);
  bool _healthBootstrapped = false;

  @override
  void initState() {
    super.initState();
    BackgroundSync.register(_sync);
    _load();
  }

  /// Runs once on startup: wipe stale Keychain entries on a fresh install,
  /// then fetch the snapshot. A 401 / missing token surfaces as an
  /// [UnauthenticatedException] → [AuthScreen]; any other error → retryable
  /// error view. 200 → Home.
  Future<void> _load() async {
    try {
      await _storage.ensureFreshInstallIsClean();
      // Ask for HealthKit access up front — before sign-in — so the system
      // sheet appears at launch, not after auth.
      await _ensureHealthPermissions();
      final snap = await UserRepository().loadCurrent();
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _error = null;
        _loading = false;
      });
      _bootstrapHealth();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } finally {
      _dismissNativeSplash();
    }
  }

  /// Tell the native side to fade out the launch-screen overlay — but only
  /// after the frame carrying the real destination (Home/Auth/error) has been
  /// laid out, so the splash never lifts onto a blank frame.
  void _dismissNativeSplash() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _splashChannel.invokeMethod('remove');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// AuthScreen calls this after a successful login/signup AND after it has
  /// already fetched the snapshot itself — so the home page renders
  /// immediately on the next frame, no intermediate loading state.
  void _onAuthenticated(UserSnapshot snapshot) {
    setState(() {
      _snapshot = snapshot;
      _error = null;
    });
    _bootstrapHealth();
  }

  /// Ask for HealthKit access ONCE, up front at launch (before the user signs
  /// in). Idempotent across launches via the persisted flag.
  Future<void> _ensureHealthPermissions() async {
    if (await _storage.getPermissionsAsked()) return;
    await _health.requestPermissions();
    await _storage.setPermissionsAsked();
  }

  /// Start the initial sync + background observers. These upload to the
  /// backend, so they need a token — only runs once authenticated (snapshot
  /// loaded, or just logged in). Permissions are handled separately, earlier.
  Future<void> _bootstrapHealth() async {
    if (_healthBootstrapped) return;
    _healthBootstrapped = true;
    unawaited(_sync.syncOnce());
    unawaited(BackgroundSync.startObservers());
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      final snap = await UserRepository().loadCurrent();
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _error = null;
        _retrying = false;
      });
      _bootstrapHealth();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _retrying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SkinScope.of(context).components;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: c.background(child: SafeArea(child: _buildContent())),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoadingView();
    }
    if (_snapshot != null) {
      return AppStateScope(
        notifier: AppState(snapshot: _snapshot!),
        child: PageView(
          controller: _controller,
          children: const [
            SideQuestsScreen(),
            HomeScreen(),
            LeaderboardScreen(),
          ],
        ),
      );
    }
    if (_error is UnauthenticatedException) {
      return AuthScreen(onAuthenticated: _onAuthenticated);
    }
    return _buildErrorView();
  }

  /// Loading state, normally invisible: the native splash overlay (installed
  /// in AppDelegate) sits on top until `_load()` finishes, so this only shows
  /// as a fallback if that overlay ever fails to attach. Matches the launch
  /// screen's gradient so even then there's no jarring flash.
  Widget _buildLoadingView() => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D0421), Color(0xFFA893CC)],
      ),
    ),
    child: SizedBox.expand(),
  );

  Widget _buildErrorView() {
    final p = SkinScope.of(context).palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CONNECTION LOST',
              style: TextStyle(
                color: p.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_error ?? 'Unknown error'}',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _retrying ? null : _retry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _retrying
                      ? p.primary.withValues(alpha: 0.4)
                      : p.primary,
                  border: Border.all(color: p.accent, width: 3),
                ),
                child: Text(
                  _retrying ? '...' : 'RETRY',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
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
