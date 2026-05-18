import 'package:flutter/widgets.dart';

import '../theme/time_of_day_palette.dart';
import 'component_library.dart';

/// Wires a single `ComponentLibrary` and `Palette` into the tree.
///
/// Screens read these via `SkinScope.of(context)` and never construct widgets
/// directly — swap a skin here and the whole UI changes with zero screen edits.
class SkinScope extends InheritedWidget {
  final ComponentLibrary components;
  final Palette palette;

  const SkinScope({
    super.key,
    required this.components,
    required this.palette,
    required super.child,
  });

  static SkinScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SkinScope>();
    assert(scope != null, 'No SkinScope found. Wrap your app in a SkinScope.');
    return scope!;
  }

  @override
  bool updateShouldNotify(SkinScope oldWidget) =>
      components != oldWidget.components ||
      palette != oldWidget.palette;
}
