import 'package:flutter/material.dart';

import '../core/models/user_snapshot.dart';
import '../core/repositories/user_repository.dart';
import '../ui/contracts/skin_scope.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<UserSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = UserRepository().loadCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final scope = SkinScope.of(context);
    final c = scope.components;
    final p = scope.palette;

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
            final data = snap.data!;
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                c.topBar(
                  userName: data.user.displayName,
                  arena: data.user.arena,
                  trophies: data.user.trophies,
                ),
                const SizedBox(height: 8),
                c.xpBar(
                  earned: data.today.xpEarned,
                  goal: data.today.xpDailyGoal,
                  progress: data.today.xpProgress,
                ),
                c.sectionHeader(label: 'Weekly Boss — ${data.dojo.name}'),
                c.bossFightCard(boss: data.dojo.weeklyBoss),
                if (data.dojo.activeBuffs.isNotEmpty) ...[
                  c.sectionHeader(label: 'Active Buffs'),
                  ...data.dojo.activeBuffs.map((b) => c.buffPill(buff: b)),
                ],
                c.sectionHeader(label: "Today's Quests"),
                ...data.quests.map((q) => c.questCard(quest: q)),
                c.sectionHeader(label: 'Chests'),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.chests.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => c.chestTile(chest: data.chests[i]),
                  ),
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}
