import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/app_state.dart';
import '../../../core/models/user_snapshot.dart';
import '../../contracts/component_library.dart';
import '../../contracts/skin_scope.dart';

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
  Widget profileSheet({required UserProfile user}) => _ProfileSheet(user: user);

  @override
  Widget sectionHeader({required String label}) => _SectionHeader(label: label);

  @override
  Widget avatar({
    required String avatarKey,
    required String displayName,
    String? subtitle,
  }) => _Avatar(
    avatarKey: avatarKey,
    displayName: displayName,
    subtitle: subtitle,
  );

  @override
  Widget xpBar({
    required int earned,
    required int goal,
    required double progress,
    VoidCallback? onTap,
  }) => _XpBar(earned: earned, goal: goal, progress: progress, onTap: onTap);

  @override
  Widget xpBreakdownSheet({
    required int earned,
    required int goal,
    required List<XpGain> items,
  }) => _XpBreakdownSheet(earned: earned, goal: goal, items: items);

  @override
  Widget questPickerTile({
    required Quest quest,
    required bool isActive,
    required bool canActivate,
    required VoidCallback onTap,
  }) => _QuestPickerTile(
    quest: quest,
    isActive: isActive,
    canActivate: canActivate,
    onTap: onTap,
  );

  @override
  Widget friendRow({
    required Friend friend,
    required bool isCurrentUser,
    required VoidCallback onTap,
  }) => _FriendRow(friend: friend, isCurrentUser: isCurrentUser, onTap: onTap);

  @override
  Widget friendDetailHeader({required FriendDetail friend}) =>
      _FriendDetailHeader(friend: friend);

  @override
  Widget friendDailyXpRow({required DailyXp entry, required bool isToday}) =>
      _FriendDailyXpRow(entry: entry, isToday: isToday);
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
      letterSpacing: 1.2,
      height: 1.2,
    );

class _Background extends StatefulWidget {
  final Widget child;
  const _Background({required this.child});

  @override
  State<_Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<_Background>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // Slow scroll for the grid floor — matches the strolling pace of the
    // ronin without being distracting on text-heavy screens.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => CustomPaint(
            painter: _SceneBackgroundPainter(
              primary: p.primary,
              accent: p.accent,
              bg: p.background,
              t: _ctrl.value,
            ),
          ),
        ),
        // Light darkening to keep on-top text legible against the bright sun.
        DecoratedBox(
          decoration: BoxDecoration(
            color: p.background.withValues(alpha: 0.18),
          ),
        ),
        widget.child,
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
    final p = SkinScope.of(context).palette;
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
          child: Text(
            'P',
            style: _mono(p.accent, size: 14, w: FontWeight.w900),
          ),
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
    final snap = AppStateScope.of(context).snapshot;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileHero(user: user),
          const SizedBox(height: 22),

          const _ProfileSectionLabel(label: 'Today'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'XP EARNED',
                  value: '${snap.today.xpEarned}',
                  sub: '/ ${snap.today.xpDailyGoal}',
                  stripe: p.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'CRIT STRIKES',
                  value: '${snap.today.criticalStrikes}',
                  stripe: p.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          const _ProfileSectionLabel(label: 'Record'),
          const SizedBox(height: 4),
          if (user.country != null)
            _DataRow(label: 'COUNTRY', value: user.country!.toUpperCase()),
          _DataRow(label: 'JOINED', value: user.joinedAt),
          _DataRow(label: 'AVATAR', value: user.avatar.toUpperCase()),
          _DataRow(label: 'ID', value: user.id.toUpperCase()),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final UserProfile user;
  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _PixelAvatarBlock(
          avatarKey: user.avatar,
          size: 96,
          primary: p.primary,
          accent: p.accent,
          bg: p.background,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName.toUpperCase(),
                style: _mono(p.textPrimary, size: 22, w: FontWeight.w900),
              ),
              if (user.country != null) ...[
                const SizedBox(height: 4),
                Text(
                  user.country!.toUpperCase(),
                  style: _mono(p.accent, size: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  final String label;
  const _ProfileSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Row(
      children: [
        Container(width: 6, height: 6, color: p.accent),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: _mono(p.textPrimary, size: 11, w: FontWeight.w800),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: p.textMuted.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color stripe;
  const _StatTile({
    required this.label,
    required this.value,
    this.sub,
    required this.stripe,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(left: BorderSide(color: stripe, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _mono(p.textMuted, size: 9)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: _mono(p.textPrimary, size: 20, w: FontWeight.w900),
              ),
              if (sub != null) ...[
                const SizedBox(width: 4),
                Text(sub!, style: _mono(p.textMuted, size: 11)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: p.textMuted.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: _mono(p.textMuted, size: 11)),
          ),
          Expanded(
            child: Text(
              value,
              style: _mono(p.textPrimary, size: 13, w: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
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
          Text(
            label.toUpperCase(),
            style: _mono(p.textPrimary, size: 11, w: FontWeight.w800),
          ),
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
  final String? subtitle;
  const _Avatar({
    required this.avatarKey,
    required this.displayName,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return Column(
      children: [
        _PixelAvatarBlock(
          avatarKey: avatarKey,
          size: 264,
          primary: p.primary,
          accent: p.accent,
          bg: p.surface,
        ),
        const SizedBox(height: 18),
        Text(
          displayName.toUpperCase(),
          style: _mono(p.textPrimary, size: 26, w: FontWeight.w900),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(subtitle!.toUpperCase(), style: _mono(p.textMuted, size: 12)),
        ],
      ],
    );
  }
}

/// A cyberpunk ronin sprite with idle animation.
///
/// The sprite is a 22×28 grid drawn each frame with a small set of palette
/// colors. The Ticker-driven loop breathes (vertical bob on the upper body),
/// pulses the visor glow, and sways the hair tips slightly so the figure
/// never reads as static.
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
      duration: const Duration(milliseconds: 1800),
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
      builder: (context, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _PixelAvatarPainter(
            seed: widget.avatarKey,
            primary: widget.primary,
            accent: widget.accent,
            t: _ctrl.value,
          ),
        ),
      ),
    );
  }
}

/// Sprite map for the cyberpunk ronin. 28 rows × 22 cols.
///   `.` empty       `K` hair (dark indigo)    `R` headband (red)
///   `S` skin        `V` visor (glow strip)    `J` jacket main
///   `T` jacket trim `D` jacket shadow         `M` belt buckle
///   `P` pants       `B` boots
const List<String> _avatarSprite = <String>[
  '........KKKKKK........',
  '.......KKKKKKKK.......',
  '......KKKKKKKKKK......',
  '.....KKKKKKKKKKKK.....',
  '.....KRRRRRRRRRRK.....',
  '.....KRRRRRRRRRRK.....',
  '.....KKSSSSSSSSKK.....',
  '.....KSSSSSSSSSSK.....',
  '.....KSSVVSSVVSSK.....',
  '.....KSSVVSSVVSSK.....',
  '.....KSSSSSSSSSSK.....',
  '.....KKSSSSSSSSKK.....',
  '......KSSSSSSSSK......',
  '........KSSSSK........',
  '.....TTTTTTTTTTTT.....',
  '....TJJJJJJJJJJJJT....',
  '....TJJJJDDDDJJJJT....',
  '....TJJJJDDDDJJJJT....',
  '...TJJJJJJDDJJJJJJT...',
  '...TJJJJJJJJJJJJJJT...',
  '....TJJTTTTTTTTJJT....',
  '....TJJMMMMMMMMJJT....',
  '.....JJJJJJJJJJJJ.....',
  '......PPPP..PPPP......',
  '......PPPP..PPPP......',
  '......PPPP..PPPP......',
  '......PPPP..PPPP......',
  '......BBBB..BBBB......',
];

class _PixelAvatarPainter extends CustomPainter {
  final String seed;
  final Color primary;
  final Color accent;
  final double t; // 0..1

  _PixelAvatarPainter({
    required this.seed,
    required this.primary,
    required this.accent,
    required this.t,
  });

  // Fixed (non palette-driven) sprite colors. These give the ronin a
  // consistent identity across time-of-day palette shifts, while the
  // jacket/trim continue to pick up the primary/accent.
  static const _hair = Color(0xFF15102E);
  static const _hairLit = Color(0xFF2A1F55);
  static const _band = Color(0xFFE5364C);
  static const _bandLit = Color(0xFFFF6A7C);
  static const _skin = Color(0xFFE8B89B);
  static const _skinLit = Color(0xFFF5D4BC);
  static const _pants = Color(0xFF2A1F40);
  static const _boots = Color(0xFF120A22);

  @override
  void paint(Canvas canvas, Size size) {
    final rows = _avatarSprite.length;
    final cols = _avatarSprite.first.length;
    final cell = math.min(size.width / cols, size.height / rows);
    final dxBase = (size.width - cell * cols) / 2;
    final dyBase = (size.height - cell * rows) / 2;

    // Walking back-and-forth across the canvas, 1 round-trip per cycle.
    final walkX = math.sin(t * 2 * math.pi) * size.width * 0.10;

    // 4 steps per cycle. Each step lifts one leg, alternating.
    final stepIdx = (t * 4).floor() % 2; // 0 or 1 — which leg is up
    final stepProgress = (t * 4) % 1; // 0..1 within the current step
    final stepCurve = math.sin(
      stepProgress * math.pi,
    ); // 0 → 1 → 0 over the step
    final legLift = stepCurve * cell * 0.55; // foot lifts off the ground
    final bodyBob = -stepCurve * cell * 0.20; // body rises mid-step

    // Visor glow pulses through the cycle.
    final breath = math.sin(t * 2 * math.pi);
    final visorMix = (breath + 1) / 2;
    final visor = Color.lerp(accent, const Color(0xFFFFFFFF), 0.4 * visorMix)!;

    // Hair tips drift slightly with motion.
    final sway = math.sin(t * 2 * math.pi) * 1.2;

    final jacketMain = Paint()..color = primary;
    final jacketTrim = Paint()..color = accent;
    final jacketShadow = Paint()..color = _shade(primary, 0.55);
    final buckle = Paint()
      ..color = Color.lerp(accent, const Color(0xFFFFFFFF), 0.25)!;

    for (int y = 0; y < rows; y++) {
      final line = _avatarSprite[y];
      for (int x = 0; x < cols; x++) {
        final c = line[x];
        if (c == '.') continue;

        Paint paint;
        double localDy = bodyBob;
        double localDx = walkX;

        switch (c) {
          case 'K':
            paint = (x >= cols / 2)
                ? (Paint()..color = _hairLit)
                : (Paint()..color = _hair);
            if (y < 3) {
              localDx += sway;
            }
            break;
          case 'R':
            paint = (x == cols / 2 - 1 || x == cols / 2)
                ? (Paint()..color = _bandLit)
                : (Paint()..color = _band);
            break;
          case 'S':
            paint = (x > cols / 2)
                ? (Paint()..color = _skinLit)
                : (Paint()..color = _skin);
            break;
          case 'V':
            paint = Paint()..color = visor;
            break;
          case 'J':
            paint = jacketMain;
            break;
          case 'T':
            paint = jacketTrim;
            break;
          case 'D':
            paint = jacketShadow;
            break;
          case 'M':
            paint = buckle;
            break;
          case 'P':
          case 'B':
            // Identify viewer-left vs viewer-right leg, then lift whichever
            // one is currently mid-stride. Planted leg keeps both feet on
            // the ground (no bob, no lift) — sells the heel-strike.
            final isLeftLeg = x < cols / 2;
            final liftedIsLeft = stepIdx == 0;
            final amILifted = isLeftLeg == liftedIsLeft;
            localDy = amILifted ? (bodyBob - legLift) : 0;
            paint = Paint()..color = c == 'P' ? _pants : _boots;
            break;
          default:
            paint = jacketMain;
        }

        canvas.drawRect(
          Rect.fromLTWH(
            dxBase + x * cell + localDx,
            dyBase + y * cell + localDy,
            cell + 0.5,
            cell + 0.5,
          ),
          paint,
        );
      }
    }
  }

  /// Darken a color toward black by `amount` (0..1).
  static Color _shade(Color c, double amount) {
    final r = (c.r * 255.0 * amount).round().clamp(0, 255);
    final g = (c.g * 255.0 * amount).round().clamp(0, 255);
    final b = (c.b * 255.0 * amount).round().clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  bool shouldRepaint(covariant _PixelAvatarPainter oldDelegate) =>
      oldDelegate.seed != seed ||
      oldDelegate.primary != primary ||
      oldDelegate.accent != accent ||
      oldDelegate.t != t;
}

/// Synthwave scene behind the ronin: gradient sky, retro sun with
/// horizontal stripe cutouts, neon horizon, perspective grid floor that
/// scrolls toward the viewer.
class _SceneBackgroundPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final Color bg;
  final double t; // 0..1, loops

  _SceneBackgroundPainter({
    required this.primary,
    required this.accent,
    required this.bg,
    required this.t,
  });

  static const _skyTop = Color(0xFF0B0420);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.72;
    final floorH = h - horizonY;

    // ---------- sky ----------
    final skyRect = Rect.fromLTWH(0, 0, w, horizonY);
    final skyBottom = _shade(primary, 0.30);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, skyBottom],
        ).createShader(skyRect),
    );

    // ---------- stars ----------
    // Deterministic constellation — looks intentional, twinkles independently.
    const stars = <List<double>>[
      [0.08, 0.10],
      [0.18, 0.22],
      [0.28, 0.06],
      [0.40, 0.16],
      [0.55, 0.09],
      [0.70, 0.20],
      [0.82, 0.08],
      [0.92, 0.30],
      [0.12, 0.40],
      [0.36, 0.48],
      [0.68, 0.42],
      [0.88, 0.52],
    ];
    final starPaint = Paint();
    for (int i = 0; i < stars.length; i++) {
      final s = stars[i];
      final twinkle = (math.sin(t * 2 * math.pi + i * 0.9) + 1) / 2; // 0..1
      starPaint.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: 0.25 + 0.55 * twinkle);
      canvas.drawCircle(
        Offset(s[0] * w, s[1] * horizonY),
        0.8 + 0.6 * twinkle,
        starPaint,
      );
    }

    // ---------- retro sun (half-sun rising at horizon) ----------
    // Anchored on the horizon so the bottom half is clipped by the floor —
    // gives you the iconic half-circle. Sized off the smaller dimension so
    // it stays a recognizable circle on both narrow and wide screens.
    final sunCenter = Offset(w * 0.5, horizonY);
    final sunR = math.min(w, h) * 0.38;
    final sunRect = Rect.fromCircle(center: sunCenter, radius: sunR);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, horizonY));
    canvas.drawCircle(
      sunCenter,
      sunR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(accent, const Color(0xFFFFE4B0), 0.55)!,
            primary,
            _shade(primary, 0.55),
          ],
        ).createShader(sunRect),
    );
    canvas.restore();

    // ---------- horizon line + glow ----------
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY - 4, w, 5),
      Paint()..color = accent.withValues(alpha: 0.18),
    );
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(w, horizonY),
      Paint()
        ..color = accent
        ..strokeWidth = 1.5,
    );

    // ---------- flat floor ----------
    // Smooth dark gradient below the horizon — no lines, no patterns. Lets
    // the ronin and sun carry the scene.
    final floorRect = Rect.fromLTWH(0, horizonY, w, floorH);
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_shade(primary, 0.18), _shade(primary, 0.06)],
        ).createShader(floorRect),
    );
  }

  static Color _shade(Color c, double amount) {
    final r = (c.r * 255.0 * amount).round().clamp(0, 255);
    final g = (c.g * 255.0 * amount).round().clamp(0, 255);
    final b = (c.b * 255.0 * amount).round().clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  bool shouldRepaint(covariant _SceneBackgroundPainter old) =>
      old.t != t ||
      old.primary != primary ||
      old.accent != accent ||
      old.bg != bg;
}

class _XpBar extends StatelessWidget {
  final int earned;
  final int goal;
  final double progress;
  final VoidCallback? onTap;
  const _XpBar({
    required this.earned,
    required this.goal,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    final bar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('DAILY XP', style: _mono(p.textMuted, size: 10)),
              const Spacer(),
              Text(
                '$earned / $goal',
                style: _mono(p.textPrimary, size: 12, w: FontWeight.w800),
              ),
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
                      boxShadow: [BoxShadow(color: p.primary, blurRadius: 8)],
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
    if (onTap == null) return bar;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: bar,
    );
  }
}

class _XpBreakdownSheet extends StatelessWidget {
  final int earned;
  final int goal;
  final List<XpGain> items;
  const _XpBreakdownSheet({
    required this.earned,
    required this.goal,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TODAY · XP EARNED', style: _mono(p.textMuted, size: 10)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$earned',
                      style: _mono(p.primary, size: 32, w: FontWeight.w900),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/ $goal XP',
                        style: _mono(p.textMuted, size: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _ProfileSectionLabel(label: 'Sources'),
          const SizedBox(height: 6),
          for (final item in items) _XpGainRow(item: item),
        ],
      ),
    );
  }
}

class _XpGainRow extends StatelessWidget {
  final XpGain item;
  const _XpGainRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    final (tag, stripe) = switch (item.source) {
      XpSource.quest => ('QUEST', p.primary),
      XpSource.crit => ('CRIT', p.accent),
      XpSource.activity => ('ACTIVITY', p.textMuted),
    };
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(left: BorderSide(color: stripe, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag, style: _mono(stripe, size: 9, w: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  item.label.toUpperCase(),
                  style: _mono(p.textPrimary, size: 12, w: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${item.xp} XP',
            style: _mono(stripe, size: 13, w: FontWeight.w900),
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
    final borderColor = isActive
        ? p.primary
        : (enabled ? p.accent : p.textMuted);
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
                    Text(
                      quest.title.toUpperCase(),
                      style: _mono(p.textPrimary, size: 12, w: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quest.current} / ${quest.target}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _mono(p.textMuted, size: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${quest.xpReward} XP',
                    style: _mono(borderColor, size: 11, w: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      actionLabel,
                      style: _mono(borderColor, size: 9),
                    ),
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

class _FriendRow extends StatelessWidget {
  final Friend friend;
  final bool isCurrentUser;
  final VoidCallback onTap;
  const _FriendRow({
    required this.friend,
    required this.isCurrentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    final isTop = friend.rank == 1;
    final accentColor = isCurrentUser
        ? p.primary
        : (isTop ? p.primary : p.accent);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser ? p.primary.withValues(alpha: 0.12) : p.surface,
          border: Border.all(color: accentColor, width: 2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#${friend.rank}',
                style: _mono(accentColor, size: 14, w: FontWeight.w900),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName.toUpperCase(),
                    style: _mono(p.textPrimary, size: 14, w: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (friend.country != null) friend.country!.toUpperCase(),
                      'today +${friend.dailyXp}',
                    ].join('  •  '),
                    style: _mono(p.textMuted, size: 10),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${friend.totalXp}',
                  style: _mono(accentColor, size: 16, w: FontWeight.w900),
                ),
                Text('TOTAL XP', style: _mono(p.textMuted, size: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendDetailHeader extends StatelessWidget {
  final FriendDetail friend;
  const _FriendDetailHeader({required this.friend});

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
          Text(
            friend.displayName.toUpperCase(),
            style: _mono(p.textPrimary, size: 22, w: FontWeight.w900),
          ),
          if (friend.country != null || friend.rank != null) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (friend.rank != null) 'RANK #${friend.rank}',
                if (friend.country != null) friend.country!.toUpperCase(),
                'JOINED ${friend.joinedAt}',
              ].join('  •  '),
              style: _mono(p.textMuted, size: 11),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${friend.totalXp}',
                style: _mono(p.primary, size: 30, w: FontWeight.w900),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'TOTAL XP  •  +${friend.dailyXp} TODAY',
                  style: _mono(p.textMuted, size: 11),
                ),
              ),
            ],
          ),
          if (friend.bio != null && friend.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(friend.bio!, style: _mono(p.textPrimary, size: 12)),
          ],
        ],
      ),
    );
  }
}

class _FriendDailyXpRow extends StatelessWidget {
  final DailyXp entry;
  final bool isToday;
  const _FriendDailyXpRow({required this.entry, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final p = SkinScope.of(context).palette;
    final highlight = isToday ? p.primary : p.textMuted;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isToday
            ? p.primary.withValues(alpha: 0.12)
            : p.surface.withValues(alpha: 0.7),
        border: Border.all(
          color: isToday ? p.primary : p.textMuted.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.day,
              style: _mono(p.textPrimary, size: 13, w: FontWeight.w700),
            ),
          ),
          Text(
            '+${entry.xp} XP',
            style: _mono(highlight, size: 13, w: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
