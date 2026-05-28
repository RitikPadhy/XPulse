import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models/user_snapshot.dart';
import '../core/repositories/user_repository.dart';
import '../core/services/background_sync.dart';
import '../core/services/health_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/sync_service.dart';
import '../ui/contracts/skin_scope.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'side_quests_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final Future<UserSnapshot> _future;
  final _controller = PageController(initialPage: 1);

  final _storage = StorageService.instance;
  final _health = HealthService();
  late final _sync = SyncService(health: _health, storage: _storage);

  final _tokenController = TextEditingController();
  bool _tokenReady = false;
  bool _initStarted = false;

  @override
  void initState() {
    super.initState();
    _future = UserRepository().loadCurrent();
    BackgroundSync.register(_sync);
    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  /// First-launch flow: ensure token + HealthKit permissions exist, then
  /// kick off initial sync and start HKObserverQueries on iOS. Idempotent —
  /// runs once per app launch but is safe if it runs again.
  Future<void> _bootstrap() async {
    if (_initStarted) return;
    _initStarted = true;

    final token = await _storage.getApiToken();
    if (token == null || token.isEmpty) {
      // Token paste sheet handles _onTokenSaved continuation.
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptForToken());
      return;
    }
    setState(() => _tokenReady = true);
    await _ensurePermissionsAndStart();
  }

  Future<void> _ensurePermissionsAndStart() async {
    final asked = await _storage.getPermissionsAsked();
    if (!asked) {
      await _health.requestPermissions();
      await _storage.setPermissionsAsked();
    }
    // Initial sync (foreground). Errors are surfaced to log only.
    unawaited(_sync.syncOnce());
    // Register HKObserverQueries on iOS so iOS wakes us on new samples.
    unawaited(BackgroundSync.startObservers());
  }

  Future<void> _promptForToken() async {
    final token = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste API token'),
        content: TextField(
          controller: _tokenController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final v = _tokenController.text.trim();
              if (v.isEmpty) return;
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (token == null || token.isEmpty) {
      // User dismissed somehow — retry next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptForToken());
      return;
    }
    await _storage.setApiToken(token);
    _tokenController.clear();
    if (!mounted) return;
    setState(() => _tokenReady = true);
    await _ensurePermissionsAndStart();
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
              if (!snap.hasData) {
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

