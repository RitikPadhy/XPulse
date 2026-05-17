import 'package:flutter/widgets.dart';

import '../../core/models/user_snapshot.dart';

/// The contract every UI skin must implement.
///
/// Screens never construct widgets directly — they ask the active
/// `ComponentLibrary` for one. Swapping the entire UI means writing a new
/// implementation and flipping it at app root.
abstract class ComponentLibrary {
  String get name;

  Widget background({required Widget child});

  Widget topBar({required String userName, required String arena, required int trophies});

  Widget xpBar({required int earned, required int goal, required double progress});

  Widget questCard({required Quest quest});

  Widget bossFightCard({required BossFight boss});

  Widget buffPill({required Buff buff});

  Widget chestTile({required Chest chest});

  Widget sectionHeader({required String label});
}
