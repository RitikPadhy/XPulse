import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models/user_snapshot.dart';
import '../core/repositories/user_repository.dart';
import '../ui/contracts/skin_scope.dart';
import 'health_setup_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _future = UserRepository().loadCurrent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                    HealthSetupScreen(),
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
