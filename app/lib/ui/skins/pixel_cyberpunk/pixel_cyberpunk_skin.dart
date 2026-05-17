import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

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
  Widget pageHeader({required String title, Widget? trailing}) =>
      _PageHeader(title: title, trailing: trailing);

  @override
  Widget profileButton({required VoidCallback onTap}) =>
      _ProfileButton(onTap: onTap);

  @override
  Widget profileSheet({required UserProfile user}) =>
      _ProfileSheet(user: user);

  @override
  Widget sectionHeader({required String label}) => _SectionHeader(label: label);

  @override
  Widget avatar({
    required String avatarKey,
    required String displayName,
    required String arena,
  }) =>
      _Avatar(avatarKey: avatarKey, displayName: displayName, arena: arena);

  @override
  Widget xpBar({
    required int earned,
    required int goal,
    required double progress,
  }) =>
      _XpBar(earned: earned, goal: goal, progress: progress);

  @override
  Widget questPickerTile({
    required Quest quest,
    required bool isActive,
    required bool canActivate,
    required VoidCallback onTap,
  }) =>
      _QuestPickerTile(
        quest: quest,
        isActive: isActive,
        canActivate: canActivate,
        onTap: onTap,
      );

  @override
  Widget clanRow({
    required int rank,
    required Clan clan,
    required VoidCallback onTap,
  }) =>
      _ClanRow(rank: rank, clan: clan, onTap: onTap);

  @override
  Widget clanDetailHeader({required Clan clan}) => _ClanDetailHeader(clan: clan);

  @override
  Widget memberRow({
    required int rank,
    required ClanMember member,
    required bool isCurrentUser,
  }) =>
      _MemberRow(rank: rank, member: member, isCurrentUser: isCurrentUser);
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
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: p.backgroundGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: p.background.withValues(alpha: 0.72),
          ),
        ),
        child,
      ],
    );
  }
}


class _PageHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _PageHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scope = SkinScope.of(context);
    final p = scope.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.primary, width: 2),
            ),
            child: Text('XPULSE', style: _mono(p.primary, size: 10)),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: _mono(p.textPrimary, size: 12, w: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Text(
            '·  ${labelFor(scope.band)}'.toUpperCase(),
            style: _mono(p.textMuted, size: 9),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.accent, width: 2),
        ),
        child: Center(
          child: Text('P', style: _mono(p.accent, size: 14, w: FontWeight.w900)),
        ),
      ),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  final UserProfile user;
  const _ProfileSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.primary, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _PixelAvatarBlock(
                avatarKey: user.avatar,
                size: 56,
                primary: p.primary,
                accent: p.accent,
                bg: p.background,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName.toUpperCase(),
                        style: _mono(p.textPrimary,
                            size: 18, w: FontWeight.w900)),
                    Text(user.arena.toUpperCase(),
                        style: _mono(p.accent, size: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProfileRow(label: 'AGE', value: '${user.age}'),
          _ProfileRow(label: 'JOINED', value: user.joinedAt),
          _ProfileRow(label: 'TROPHIES', value: '${user.trophies}'),
          _ProfileRow(label: 'AVATAR', value: user.avatar.toUpperCase()),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: _mono(p.textMuted, size: 11)),
          ),
          Expanded(
            child: Text(value,
                style: _mono(p.textPrimary, size: 13, w: FontWeight.w800)),
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

class _Avatar extends StatelessWidget {
  final String avatarKey;
  final String displayName;
  final String arena;
  const _Avatar({
    required this.avatarKey,
    required this.displayName,
    required this.arena,
  });

  static const _modelPath = 'assets/characters/avatar.glb';

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Column(
      children: [
        SizedBox(
          width: 240,
          height: 280,
          // Brighten the character globally — WebView's default lighting is
          // dim, which makes light-skinned models render as muddy/dark.
          // Matrix: RGB *= 1.25 with +35 offset so shadows lift first, brights
          // saturate gracefully into white.
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              1.25, 0, 0, 0, 35,
              0, 1.25, 0, 0, 35,
              0, 0, 1.25, 0, 35,
              0, 0, 0, 1, 0,
            ]),
            child: _LiveCharacter(
              src: _modelPath,
              fallback: _PixelAvatarBlock(
                avatarKey: avatarKey,
                size: 240,
                primary: p.primary,
                accent: p.accent,
                bg: p.surface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          displayName.toUpperCase(),
          style: _mono(p.textPrimary, size: 26, w: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(arena.toUpperCase(), style: _mono(p.accent, size: 12)),
      ],
    );
  }
}

/// Tries to render a 3D `.glb` character. If the asset is missing, shows
/// the supplied fallback (e.g. the procedural pixel sprite).
class _LiveCharacter extends StatefulWidget {
  final String src;
  final Widget fallback;
  const _LiveCharacter({required this.src, required this.fallback});

  @override
  State<_LiveCharacter> createState() => _LiveCharacterState();
}

class _LiveCharacterState extends State<_LiveCharacter> {
  late final Future<bool> _hasAsset;
  final Flutter3DController _controller = Flutter3DController();

  @override
  void initState() {
    super.initState();
    _hasAsset = _checkAsset();
  }

  Future<bool> _checkAsset() async {
    try {
      final bytes = await rootBundle.load(widget.src);
      return bytes.lengthInBytes > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasAsset,
      builder: (ctx, snap) {
        if (!snap.hasData) return widget.fallback;
        if (snap.data != true) return widget.fallback;
        return Flutter3DViewer(
          src: widget.src,
          controller: _controller,
          activeGestureInterceptor: false,
          onLoad: (_) async {
            // Frame the character close enough to read the face clearly.
            _controller.setCameraOrbit(0, 78, 110);
            _controller.setCameraTarget(0, 1, 0);
            final anims = await _controller.getAvailableAnimations();
            if (anims.isEmpty) return;
            // Prefer Run > Walk > Dance > Idle > first.
            // This way whichever .glb is dropped in, we pick the liveliest loop.
            String pick = anims.first;
            for (final keyword in ['run', 'walk', 'dance', 'idle']) {
              final matches =
                  anims.where((a) => a.toLowerCase().contains(keyword));
              if (matches.isNotEmpty) {
                pick = matches.first;
                break;
              }
            }
            _controller.playAnimation(animationName: pick);
          },
        );
      },
    );
  }
}

/// A humanoid pixel-art character with idle animation.
///
/// The sprite itself is a fixed 14×14 grid; what makes it feel alive is a
/// Ticker-driven loop that breathes (vertical bob + glow pulse), sways the
/// arms slightly out-of-phase with the body, and blinks once per cycle.
class _PixelAvatarBlock extends StatefulWidget {
  final String avatarKey;
  final double size;
  final Color primary;
  final Color accent;
  final Color bg;
  const _PixelAvatarBlock({
    required this.avatarKey,
    required this.size,
    required this.primary,
    required this.accent,
    required this.bg,
  });

  @override
  State<_PixelAvatarBlock> createState() => _PixelAvatarBlockState();
}

class _PixelAvatarBlockState extends State<_PixelAvatarBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value; // 0..1
        // Breath = full sinusoid over the cycle.
        final breath = math.sin(t * 2 * math.pi);
        final glowAlpha = 0.30 + 0.25 * ((breath + 1) / 2);
        // Quick blink window near the end of the cycle.
        final isBlinking = t > 0.92 && t < 0.97;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.bg,
            border: Border.all(color: widget.primary, width: 3),
            boxShadow: [
              BoxShadow(
                color: widget.primary.withValues(alpha: glowAlpha),
                blurRadius: 18 + 10 * ((breath + 1) / 2),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _PixelAvatarPainter(
              seed: widget.avatarKey,
              primary: widget.primary,
              accent: widget.accent,
              breath: breath,
              isBlinking: isBlinking,
            ),
          ),
        );
      },
    );
  }
}

/// Sprite map for the humanoid. 14 rows × 14 cols.
///   . empty   H head/skin   A accent strip   E eye   B body
///   R arm     L leg         F foot
const List<String> _avatarSprite = <String>[
  '....HHHHHH....',
  '...HHHHHHHH...',
  '..HHAAAAAAHH..',
  '..HHE.HH.EHH..',
  '..HHHHHHHHHH..',
  '...HHHHHHHH...',
  '..BBBBBBBBBB..',
  '.RBBAABBAABBR.',
  '.RBBBBBBBBBBR.',
  '.RBBBBBBBBBBR.',
  '..BBBBBBBBBB..',
  '..LLL....LLL..',
  '..LLL....LLL..',
  '..FFF....FFF..',
];

class _PixelAvatarPainter extends CustomPainter {
  final String seed;
  final Color primary;
  final Color accent;
  final double breath; // -1..1
  final bool isBlinking;

  _PixelAvatarPainter({
    required this.seed,
    required this.primary,
    required this.accent,
    required this.breath,
    required this.isBlinking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = _avatarSprite.length;
    final cols = _avatarSprite.first.length;
    final cell = size.width / cols;

    final body = Paint()..color = primary;
    final highlight = Paint()..color = accent;
    final eye = Paint()
      ..color = isBlinking ? primary : accent;
    final foot = Paint()..color = primary.withValues(alpha: 0.85);
    final arm = Paint()..color = accent.withValues(alpha: 0.9);

    // Breathing bob: shift the whole sprite up to 2px vertically.
    final bob = breath * 2.0;
    // Arms wave slightly opposite to breath.
    final armBob = -breath * 2.0;

    for (int y = 0; y < rows; y++) {
      final line = _avatarSprite[y];
      for (int x = 0; x < cols; x++) {
        final c = line[x];
        if (c == '.') continue;
        Paint paint;
        double dy = bob;
        switch (c) {
          case 'H':
          case 'B':
            paint = body;
            break;
          case 'A':
            paint = highlight;
            break;
          case 'E':
            paint = eye;
            break;
          case 'R':
            paint = arm;
            dy = armBob;
            break;
          case 'L':
            paint = body;
            // Legs don't bob — they're "planted."
            dy = 0;
            break;
          case 'F':
            paint = foot;
            dy = 0;
            break;
          default:
            paint = body;
        }
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell + dy, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelAvatarPainter oldDelegate) =>
      oldDelegate.seed != seed ||
      oldDelegate.primary != primary ||
      oldDelegate.accent != accent ||
      oldDelegate.breath != breath ||
      oldDelegate.isBlinking != isBlinking;
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

class _QuestPickerTile extends StatelessWidget {
  final Quest quest;
  final bool isActive;
  final bool canActivate;
  final VoidCallback onTap;
  const _QuestPickerTile({
    required this.quest,
    required this.isActive,
    required this.canActivate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    final enabled = isActive || canActivate;
    final borderColor = isActive ? p.primary : (enabled ? p.accent : p.textMuted);
    final actionLabel = isActive ? 'REMOVE' : (enabled ? 'ADD' : 'LOCKED');
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.title.toUpperCase(),
                        style:
                            _mono(p.textPrimary, size: 12, w: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      '${quest.current} / ${quest.target} ${quest.metric}',
                      style: _mono(p.textMuted, size: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${quest.xpReward} XP',
                      style: _mono(borderColor, size: 11, w: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(actionLabel,
                        style: _mono(borderColor, size: 9)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClanRow extends StatelessWidget {
  final int rank;
  final Clan clan;
  final VoidCallback onTap;
  const _ClanRow({required this.rank, required this.clan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    final isTop = rank == 1;
    final accentColor = isTop ? p.primary : p.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: accentColor, width: 2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text('#$rank',
                  style: _mono(accentColor, size: 14, w: FontWeight.w900)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clan.name.toUpperCase(),
                      style:
                          _mono(p.textPrimary, size: 14, w: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '[${clan.tag}]  •  ${clan.memberCount} members',
                    style: _mono(p.textMuted, size: 10),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${clan.totalTrophies}',
                    style: _mono(accentColor, size: 16, w: FontWeight.w900)),
                Text('TROPHIES', style: _mono(p.textMuted, size: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClanDetailHeader extends StatelessWidget {
  final Clan clan;
  const _ClanDetailHeader({required this.clan});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.primary, width: 2),
        boxShadow: [
          BoxShadow(color: p.primary.withValues(alpha: 0.35), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(clan.name.toUpperCase(),
              style: _mono(p.textPrimary, size: 22, w: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('[${clan.tag}]  •  ${clan.memberCount} MEMBERS',
              style: _mono(p.textMuted, size: 11)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${clan.totalTrophies}',
                  style: _mono(p.primary, size: 30, w: FontWeight.w900)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('TOTAL TROPHIES',
                    style: _mono(p.textMuted, size: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final int rank;
  final ClanMember member;
  final bool isCurrentUser;
  const _MemberRow({
    required this.rank,
    required this.member,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    final highlight = isCurrentUser ? p.primary : p.textMuted;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? p.primary.withValues(alpha: 0.12)
            : p.surface.withValues(alpha: 0.7),
        border: Border.all(
          color: isCurrentUser ? p.primary : p.textMuted.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#$rank',
                style: _mono(highlight, size: 12, w: FontWeight.w800)),
          ),
          Expanded(
            child: Text(member.name.toUpperCase(),
                style: _mono(p.textPrimary, size: 13, w: FontWeight.w700)),
          ),
          Text('${member.trophies}',
              style: _mono(highlight, size: 13, w: FontWeight.w800)),
        ],
      ),
    );
  }
}
