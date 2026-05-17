import 'package:flutter/material.dart';

enum TimeBand { morning, afternoon, night }

TimeBand bandFor(DateTime now) {
  final h = now.hour;
  if (h >= 6 && h < 12) return TimeBand.morning;
  if (h >= 12 && h < 18) return TimeBand.afternoon;
  return TimeBand.night;
}

class Palette {
  final Color background;
  final Color surface;
  final Color primary;
  final Color accent;
  final Color textPrimary;
  final Color textMuted;
  final List<Color> backgroundGradient;

  const Palette({
    required this.background,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textMuted,
    required this.backgroundGradient,
  });
}

const _morning = Palette(
  background: Color(0xFF120A1F),
  surface: Color(0xFF1E1230),
  primary: Color(0xFFFF6FB5),
  accent: Color(0xFF38E1FF),
  textPrimary: Color(0xFFFFE7F2),
  textMuted: Color(0xFFB591C9),
  backgroundGradient: [Color(0xFF2A0E2E), Color(0xFFFF6FB5), Color(0xFFFFB169)],
);

const _afternoon = Palette(
  background: Color(0xFF000814),
  surface: Color(0xFF0B1B2B),
  primary: Color(0xFF3FA9FF),
  accent: Color(0xFFFFFFFF),
  textPrimary: Color(0xFFE8F4FF),
  textMuted: Color(0xFF8AAEC8),
  backgroundGradient: [Color(0xFF001027), Color(0xFF0B3A6B), Color(0xFF3FA9FF)],
);

const _night = Palette(
  background: Color(0xFF05020A),
  surface: Color(0xFF110820),
  primary: Color(0xFFFF2EC4),
  accent: Color(0xFF8A4BFF),
  textPrimary: Color(0xFFEDE2FF),
  textMuted: Color(0xFF7B5BAA),
  backgroundGradient: [Color(0xFF05020A), Color(0xFF1B0533), Color(0xFFFF2EC4)],
);

Palette paletteFor(TimeBand band) => switch (band) {
      TimeBand.morning => _morning,
      TimeBand.afternoon => _afternoon,
      TimeBand.night => _night,
    };

String labelFor(TimeBand band) => switch (band) {
      TimeBand.morning => 'The Grid Bootup',
      TimeBand.afternoon => 'Active State',
      TimeBand.night => 'Neo-Tokyo Dark',
    };
