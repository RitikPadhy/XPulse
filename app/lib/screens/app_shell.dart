import 'dart:async';

import 'package:flutter/material.dart';

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
  late Future<UserSnapshot> _future = _load();
  final _controller = PageController(initialPage: 1);

  final _storage = StorageService.instance;
  final _health = HealthService();
  late final _sync = SyncService(health: _health, storage: _storage);

  bool _healthBootstrapped = false;

  @override
  void initState() {
    super.initState();
    BackgroundSync.register(_sync);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<UserSnapshot> _load() => UserRepository().loadCurrent();

  /// Called after a successful login/signup: re-fetch the snapshot and run
  /// the post-auth HealthKit bootstrap.
  void _onAuthenticated() {
    setState(() {
      _future = _load();
    });
    _bootstrapHealth();
  }

  /// One-time-per-app-launch: ask for HealthKit perms (if not asked yet),
  /// kick off the initial sync, and register iOS observers.
  Future<void> _bootstrapHealth() async {
    if (_healthBootstrapped) return;
    _healthBootstrapped = true;
    final asked = await _storage.getPermissionsAsked();
    if (!asked) {
      await _health.requestPermissions();
      await _storage.setPermissionsAsked();
    }
    unawaited(_sync.syncOnce());
    unawaited(BackgroundSync.startObservers());
  }

  @override
  Widget build(BuildContext context) {
    final c = SkinScope.of(context).components;
    final p = SkinScope.of(context).palette;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: c.background(
        child: SafeArea(
          child: FutureBuilder<UserSnapshot>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Center(
                  child: Text(
                    'BOOTING…',
                    style: TextStyle(
                      color: p.textMuted,
                      fontFamily: 'Courier',
                      letterSpacing: 2,
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                if (snap.error is UnauthenticatedException) {
                  return AuthScreen(onAuthenticated: _onAuthenticated);
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Could not load.',
                          style: TextStyle(
                            color: p.primary,
                            fontFamily: 'Courier',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snap.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: p.textMuted,
                            fontFamily: 'Courier',
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => setState(() => _future = _load()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: p.accent, width: 2),
                            ),
                            child: Text(
                              'RETRY',
                              style: TextStyle(
                                color: p.accent,
                                fontFamily: 'Courier',
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // Got the snapshot — fire-and-forget the HealthKit bootstrap.
              if (!_healthBootstrapped) {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _bootstrapHealth());
              }
              return AppStateScope(
                notifier: AppState(snapshot: snap.data!),
                child: PageView(
                  controller: _controller,
                  children: const [
                    SideQuestsScreen(),
                    HomeScreen(),
                    LeaderboardScreen(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
