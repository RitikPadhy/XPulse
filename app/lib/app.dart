import 'package:flutter/widgets.dart';

import 'screens/home_screen.dart';
import 'ui/contracts/component_library.dart';
import 'ui/contracts/skin_scope.dart';
import 'ui/skins/pixel_cyberpunk/pixel_cyberpunk_skin.dart';
import 'ui/theme/time_of_day_palette.dart';

class XPulseApp extends StatelessWidget {
  const XPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Swap this to switch the entire UI. Every screen renders through it.
    const ComponentLibrary skin = PixelCyberpunkSkin();

    final band = bandFor(DateTime.now());
    final palette = paletteFor(band);

    return WidgetsApp(
      title: 'XPulse',
      color: palette.primary,
      builder: (context, _) => SkinScope(
        components: skin,
        palette: palette,
        band: band,
        child: const HomeScreen(),
      ),
      pageRouteBuilder: <T>(settings, builder) => _NoAnimRoute<T>(builder),
    );
  }
}

class _NoAnimRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  _NoAnimRoute(this.builder);

  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      builder(context);
}
