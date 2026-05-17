import 'package:flutter/widgets.dart';

import '../../../core/models/user_snapshot.dart';
import '../../contracts/component_library.dart';
import '../../contracts/skin_scope.dart';
import '../../theme/time_of_day_palette.dart';

class PixelCyberpunkSkin implements ComponentLibrary {
  const PixelCyberpunkSkin();

  @override
  String get name => 'pixel_cyberpunk';

  @override
  Widget background({required Widget child}) => _Background(child: child);

  @override
  Widget topBar({
    required String userName,
    required String arena,
    required int trophies,
  }) =>
      _TopBar(userName: userName, arena: arena, trophies: trophies);

  @override
  Widget xpBar({
    required int earned,
    required int goal,
    required double progress,
  }) =>
      _XpBar(earned: earned, goal: goal, progress: progress);

  @override
  Widget questCard({required Quest quest}) => _QuestCard(quest: quest);

  @override
  Widget bossFightCard({required BossFight boss}) => _BossFightCard(boss: boss);

  @override
  Widget buffPill({required Buff buff}) => _BuffPill(buff: buff);

  @override
  Widget chestTile({required Chest chest}) => _ChestTile(chest: chest);

  @override
  Widget sectionHeader({required String label}) => _SectionHeader(label: label);
}

// ---------------------------------------------------------------------------
// Internal widgets — pixel-art cyberpunk implementations.
// All squared corners, neon borders, hard-edged shadows.
// ---------------------------------------------------------------------------

TextStyle _mono(Color c, {double size = 12, FontWeight w = FontWeight.w600}) =>
    TextStyle(
      color: c,
      fontSize: size,
      fontWeight: w,
      fontFamily: 'Courier',
      letterSpacing: 1.2,
      height: 1.2,
    );

class _Background extends StatelessWidget {
  final Widget child;
  const _Background({required this.child});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: p.backgroundGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.background.withValues(alpha: 0.72),
        ),
        child: child,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String userName;
  final String arena;
  final int trophies;
  const _TopBar({
    required this.userName,
    required this.arena,
    required this.trophies,
  });

  @override
  Widget build(BuildContext context) {
    final scope = SkinScope.of(context);
    final p = scope.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Mini XPulse logo — kept small per design constraint.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.primary, width: 2),
            ),
            child: Text('XPULSE', style: _mono(p.primary, size: 10)),
          ),
          const SizedBox(width: 10),
          Text(labelFor(scope.band).toUpperCase(),
              style: _mono(p.textMuted, size: 9)),
          const Spacer(),
          Text('$trophies',
              style: _mono(p.accent, size: 14, w: FontWeight.w800)),
          const SizedBox(width: 4),
          Text('TR', style: _mono(p.textMuted, size: 10)),
        ],
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  final int earned;
  final int goal;
  final double progress;
  const _XpBar({
    required this.earned,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('DAILY XP', style: _mono(p.textMuted, size: 10)),
              const Spacer(),
              Text('$earned / $goal',
                  style: _mono(p.textPrimary, size: 12, w: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          // Pixel-style bar — segmented, no rounded corners, neon fill.
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.primary, width: 2),
            ),
            child: LayoutBuilder(
              builder: (ctx, c) => Stack(
                children: [
                  Container(
                    width: c.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: p.primary,
                      boxShadow: [
                        BoxShadow(color: p.primary, blurRadius: 8),
                      ],
                    ),
                  ),
                  // Pixel segments overlay — thin vertical ticks every 10%.
                  Row(
                    children: List.generate(
                      10,
                      (_) => Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: p.background.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(width: 6, height: 6, color: p.accent),
          const SizedBox(width: 8),
          Text(label.toUpperCase(),
              style: _mono(p.textPrimary, size: 11, w: FontWeight.w800)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: p.textMuted.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;
  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    final done = quest.status == QuestStatus.complete;
    final fillColor = done ? p.accent : p.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: fillColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(quest.title.toUpperCase(),
                    style: _mono(p.textPrimary, size: 12, w: FontWeight.w800)),
              ),
              Text('+${quest.xpReward} XP', style: _mono(fillColor, size: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: p.background,
              border: Border.all(color: p.textMuted.withValues(alpha: 0.3)),
            ),
            child: LayoutBuilder(
              builder: (ctx, c) => Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: c.maxWidth * quest.progress,
                  color: fillColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${quest.current} / ${quest.target}  •  ${quest.metric}',
            style: _mono(p.textMuted, size: 10),
          ),
        ],
      ),
    );
  }
}

class _BossFightCard extends StatelessWidget {
  final BossFight boss;
  const _BossFightCard({required this.boss});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.accent, width: 2),
        boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.3), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('BOSS', style: _mono(p.accent, size: 10)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  boss.name.toUpperCase(),
                  style: _mono(p.textPrimary, size: 14, w: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(boss.objective, style: _mono(p.textMuted, size: 11)),
          const SizedBox(height: 10),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: p.background,
              border: Border.all(color: p.accent.withValues(alpha: 0.4)),
            ),
            child: LayoutBuilder(
              builder: (ctx, c) => Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: c.maxWidth * boss.fraction,
                  color: p.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${boss.progress} / ${boss.target}  •  ends ${boss.endsAt.split('T').first}',
            style: _mono(p.textMuted, size: 10),
          ),
        ],
      ),
    );
  }
}

class _BuffPill extends StatelessWidget {
  final Buff buff;
  const _BuffPill({required this.buff});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.primary.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, color: p.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(buff.name.toUpperCase(),
                    style: _mono(p.textPrimary, size: 11, w: FontWeight.w800)),
                Text(buff.description, style: _mono(p.textMuted, size: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChestTile extends StatelessWidget {
  final Chest chest;
  const _ChestTile({required this.chest});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    final rarityColor = switch (chest.rarity) {
      'rare' => p.accent,
      'epic' => p.primary,
      _ => p.textMuted,
    };
    final statusLabel = switch (chest.status) {
      ChestStatus.unlocking => 'UNLOCKING',
      ChestStatus.ready => 'READY',
      ChestStatus.pending => 'LOCKED',
    };
    return Container(
      width: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: rarityColor, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 40,
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.15),
              border: Border.all(color: rarityColor),
            ),
            child: Center(
              child: Text(
                chest.rarity.substring(0, 1).toUpperCase(),
                style: _mono(rarityColor, size: 22, w: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(statusLabel, style: _mono(p.textPrimary, size: 9)),
        ],
      ),
    );
  }
}
