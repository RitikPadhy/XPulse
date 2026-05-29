import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models/user_snapshot.dart';
import '../core/services/api_client.dart';
import '../ui/contracts/skin_scope.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Friend? _selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _selected != null
          ? _FriendDetailView(
              key: ValueKey('friend-${_selected!.id}'),
              friend: _selected!,
              onBack: () => setState(() => _selected = null),
            )
          : _LeaderboardListView(
              key: const ValueKey('leaderboard'),
              onSelect: (f) => setState(() => _selected = f),
            ),
    );
  }
}

class _LeaderboardListView extends StatelessWidget {
  final void Function(Friend friend) onSelect;
  const _LeaderboardListView({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = SkinScope.of(context).components;
    final state = AppStateScope.of(context);
    final friends = state.snapshot.friends;
    final selfId = state.snapshot.user.id;

    return Column(
      children: [
        c.pageHeader(title: 'Friends'),
        Expanded(
          child: friends.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No friends yet.',
                      style: TextStyle(
                        color: SkinScope.of(context).palette.textMuted,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: friends.length,
                  itemBuilder: (_, i) => c.friendRow(
                    friend: friends[i],
                    isCurrentUser: friends[i].id.toString() == selfId,
                    onTap: () => onSelect(friends[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FriendDetailView extends StatefulWidget {
  final Friend friend;
  final VoidCallback onBack;
  const _FriendDetailView({
    super.key,
    required this.friend,
    required this.onBack,
  });

  @override
  State<_FriendDetailView> createState() => _FriendDetailViewState();
}

class _FriendDetailViewState extends State<_FriendDetailView> {
  late final Future<FriendDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient().getFriendDetail(widget.friend.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = SkinScope.of(context).components;
    final p = SkinScope.of(context).palette;

    return Column(
      children: [
        c.pageHeader(
          title: 'Profile',
          trailing: GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: p.accent, width: 2),
              ),
              child: Text(
                'BACK',
                style: TextStyle(
                  color: p.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<FriendDetail>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load profile.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textMuted),
                    ),
                  ),
                );
              }
              if (!snap.hasData) {
                return Center(
                  child: Text(
                    'LOADING…',
                    style: TextStyle(color: p.textMuted, letterSpacing: 2),
                  ),
                );
              }
              final detail = snap.data!;
              final today = DateTime.now().toIso8601String().split('T').first;
              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  c.friendDetailHeader(friend: detail),
                  c.sectionHeader(label: 'Last 7 days'),
                  ...detail.last7Days.reversed.map(
                    (e) =>
                        c.friendDailyXpRow(entry: e, isToday: e.day == today),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
