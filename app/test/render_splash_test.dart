// One-off renderer for the iOS launch image. Run with:
//   cd app && flutter test test/render_splash_test.dart
//
// Generates three PNGs into ios/Runner/Assets.xcassets/LaunchImage.imageset/
// at @1x, @2x, @3x. Paints a quiet version of the home screen's synthwave
// backdrop — sky gradient, stars, horizon line, floor gradient — but NOT
// the sun (the launch image is the calm precursor) and NOT the wordmark
// (XPULSE is rendered synchronously as a UILabel in LaunchScreen.storyboard
// so it appears before the PNG decode completes).

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _primary = Color(0xFFFF2EC4);
const _skyTop = Color(0xFF0B0420);

void main() {
  test('render launch image', () async {
    // Logical canvas (430x932 = iPhone 15 Pro Max points)
    const logicalW = 430.0;
    const logicalH = 932.0;

    final outDir = Directory('ios/Runner/Assets.xcassets/LaunchImage.imageset');
    if (!await outDir.exists()) {
      throw StateError('Expected ${outDir.path} to exist');
    }

    for (final scale in [1.0, 2.0, 3.0]) {
      final w = (logicalW * scale).round();
      final h = (logicalH * scale).round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(scale);

      _paintScene(canvas, const Size(logicalW, logicalH));

      final picture = recorder.endRecording();
      final image = await picture.toImage(w, h);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();

      final suffix = scale == 1.0 ? '' : '@${scale.toInt()}x';
      final file = File('${outDir.path}/LaunchImage$suffix.png');
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('wrote ${file.path} ($w x $h, ${bytes.length} bytes)');
    }
  });
}

/// Full-screen sky gradient + stars only. No horizon line, no floor — those
/// belong to the home painter, not the launch screen.
void _paintScene(Canvas canvas, Size size) {
  final w = size.width;
  final h = size.height;

  // Sky gradient stretched across the whole screen so there's no abrupt
  // colour change at the bottom edge.
  final skyRect = Rect.fromLTWH(0, 0, w, h);
  canvas.drawRect(
    skyRect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_skyTop, _shade(_primary, 0.30)],
      ).createShader(skyRect),
  );

  // Stars — same deterministic constellation as the home painter, scaled
  // into the upper portion so they sit where the eye expects sky stars,
  // not down in the area the home painter uses for the floor/sun.
  const stars = <List<double>>[
    [0.08, 0.10], [0.18, 0.22], [0.28, 0.06], [0.40, 0.16],
    [0.55, 0.09], [0.70, 0.20], [0.82, 0.08], [0.92, 0.30],
    [0.12, 0.40], [0.36, 0.48], [0.68, 0.42], [0.88, 0.52],
  ];
  final skyHeight = h * 0.72; // mirrors home painter's horizon position
  final starPaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55);
  for (final s in stars) {
    canvas.drawCircle(Offset(s[0] * w, s[1] * skyHeight), 1.1, starPaint);
  }
}

Color _shade(Color c, double amount) {
  final r = (c.r * 255.0 * amount).round().clamp(0, 255);
  final g = (c.g * 255.0 * amount).round().clamp(0, 255);
  final b = (c.b * 255.0 * amount).round().clamp(0, 255);
  return Color.fromARGB(255, r, g, b);
}

