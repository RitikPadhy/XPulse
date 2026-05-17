import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../ui/contracts/skin_scope.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = SkinScope.of(context);
    final c = scope.components;
    final state = AppStateScope.of(context);
    final snap = state.snapshot;

    return Column(
      children: [
        c.pageHeader(
          title: 'Home',
          trailing: c.profileButton(
            onTap: () => _openProfile(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: c.xpBar(
            earned: snap.today.xpEarned,
            goal: snap.today.xpDailyGoal,
            progress: snap.today.xpProgress,
          ),
        ),
        const Spacer(flex: 4),
        c.avatar(
          avatarKey: snap.user.avatar,
          displayName: snap.user.displayName,
          arena: snap.user.arena,
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  void _openProfile(BuildContext context) {
    final c = SkinScope.of(context).components;
    final user = AppStateScope.of(context).snapshot.user;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => c.profileSheet(user: user),
    );
  }
}
