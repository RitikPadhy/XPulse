import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models/user_snapshot.dart';
import '../ui/contracts/skin_scope.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Clan? _selectedClan;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _selectedClan != null
          ? _ClanDetailView(
              key: ValueKey('clan-${_selectedClan!.id}'),
              clan: _selectedClan!,
              onBack: () => setState(() => _selectedClan = null),
            )
          : _LeaderboardListView(
              key: const ValueKey('leaderboard'),
              onSelectClan: (clan) =>
                  setState(() => _selectedClan = clan),
            ),
    );
  }
}

class _LeaderboardListView extends StatelessWidget {
  final void Function(Clan clan) onSelectClan;
  const _LeaderboardListView({super.key, required this.onSelectClan});

  @override
  Widget build(BuildContext context) {
    final c = SkinScope.of(context).components;
    final state = AppStateScope.of(context);
    final clans = [...state.snapshot.leaderboard]
      ..sort((a, b) => b.totalTrophies.compareTo(a.totalTrophies));

    return Column(
      children: [
        c.pageHeader(title: 'Leaderboard'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: clans.length,
            itemBuilder: (_, i) => c.clanRow(
              rank: i + 1,
              clan: clans[i],
              onTap: () => onSelectClan(clans[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClanDetailView extends StatelessWidget {
  final Clan clan;
  final VoidCallback onBack;
  const _ClanDetailView({
    super.key,
    required this.clan,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final c = SkinScope.of(context).components;
    final p = SkinScope.of(context).palette;
    final state = AppStateScope.of(context);
    final currentUserId = state.snapshot.user.id;
    final members = clan.sortedByTrophies;

    return Column(
      children: [
        c.pageHeader(
          title: 'Clan',
          trailing: GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: p.accent, width: 2),
              ),
              child: Text(
                'BACK',
                style: TextStyle(
                  color: p.accent,
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        c.clanDetailHeader(clan: clan),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: members.length,
            itemBuilder: (_, i) => c.memberRow(
              rank: i + 1,
              member: members[i],
              isCurrentUser: members[i].id == currentUserId,
            ),
          ),
        ),
      ],
    );
  }
}
