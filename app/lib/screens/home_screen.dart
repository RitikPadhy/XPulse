import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../ui/contracts/skin_scope.dart';

enum _View { home, profile, xpBreakdown }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _View _view = _View.home;

  void _go(_View v) => setState(() => _view = v);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (_view) {
        _View.profile => _ProfileView(
            key: const ValueKey('profile'),
            onBack: () => _go(_View.home),
          ),
        _View.xpBreakdown => _XpBreakdownView(
            key: const ValueKey('xp-breakdown'),
            onBack: () => _go(_View.home),
          ),
        _View.home => _HomeView(
            key: const ValueKey('home'),
            onOpenProfile: () => _go(_View.profile),
            onOpenXpBreakdown: () => _go(_View.xpBreakdown),
          ),
      },
    );
  }
}

class _HomeView extends StatelessWidget {
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenXpBreakdown;
  const _HomeView({
    super.key,
    required this.onOpenProfile,
    required this.onOpenXpBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final c = SkinScope.of(context).components;
    final snap = AppStateScope.of(context).snapshot;

    return Column(
      children: [
        c.pageHeader(
          title: 'Home',
          trailing: c.profileButton(onTap: onOpenProfile),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: c.xpBar(
            earned: snap.today.xpEarned,
            goal: snap.today.xpDailyGoal,
            progress: snap.today.xpProgress,
            onTap: onOpenXpBreakdown,
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
}

class _ProfileView extends StatelessWidget {
  final VoidCallback onBack;
  const _ProfileView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = SkinScope.of(context).components;
    final user = AppStateScope.of(context).snapshot.user;

    return Column(
      children: [
        c.pageHeader(
          title: 'Profile',
          trailing: _BackButton(onTap: onBack),
        ),
        const SizedBox(height: 12),
        Expanded(child: c.profileSheet(user: user)),
      ],
    );
  }
}

class _XpBreakdownView extends StatelessWidget {
  final VoidCallback onBack;
  const _XpBreakdownView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = SkinScope.of(context).components;
    final snap = AppStateScope.of(context).snapshot;

    return Column(
      children: [
        c.pageHeader(
          title: 'Daily XP',
          trailing: _BackButton(onTap: onBack),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: c.xpBreakdownSheet(
            earned: snap.today.xpEarned,
            goal: snap.today.xpDailyGoal,
            items: snap.xpBreakdown,
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }
}
