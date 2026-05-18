import 'package:flutter/material.dart';

/// The app uses a single, time-independent palette. Hot pink + violet on
/// black — the synthwave look that matches the cyberpunk skin.
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

const Palette appPalette = Palette(
  background: Color(0xFF05020A),
  surface: Color(0xFF110820),
  primary: Color(0xFFFF2EC4),
  accent: Color(0xFF8A4BFF),
  textPrimary: Color(0xFFEDE2FF),
  textMuted: Color(0xFF7B5BAA),
  backgroundGradient: [Color(0xFF05020A), Color(0xFF1B0533), Color(0xFFFF2EC4)],
);
