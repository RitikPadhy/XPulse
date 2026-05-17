import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'ui/contracts/component_library.dart';
import 'ui/contracts/skin_scope.dart';
import 'ui/skins/pixel_cyberpunk/pixel_cyberpunk_skin.dart';
import 'ui/theme/time_of_day_palette.dart';

class XPulseApp extends StatelessWidget {
  const XPulseApp({super.key});

  // Swap this to switch the entire UI. Every screen renders through it.
  static const ComponentLibrary skin = PixelCyberpunkSkin();

  @override
  Widget build(BuildContext context) {
    final band = bandFor(DateTime.now());
    final palette = paletteFor(band);

    return MaterialApp(
      title: 'XPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: palette.background,
      ),
      home: SkinScope(
        components: skin,
        palette: palette,
        band: band,
        child: const AppShell(),
      ),
    );
  }
}
