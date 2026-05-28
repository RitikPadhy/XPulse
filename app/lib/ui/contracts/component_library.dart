import 'package:flutter/widgets.dart';

import '../../core/models/user_snapshot.dart';

/// The contract every UI skin must implement.
///
/// Screens never construct widgets directly — they ask the active
/// `ComponentLibrary` for one. Swapping the entire UI means writing a new
/// implementation and flipping it at app root.
abstract class ComponentLibrary {
  String get name;

  /// Full-screen background — gradient, ambience, time-of-day tint.
  Widget background({required Widget child});

  /// Slim header for each page. Right-side widget is optional (e.g. profile button).
  Widget pageHeader({required String title, Widget? trailing});

  /// Small icon button shown in the top-right of the home page.
  Widget profileButton({required VoidCallback onTap});

  /// Body of the profile view (rendered inline within the home tab).
  Widget profileSheet({required UserProfile user});

  /// Section label used inside scrollable bodies.
  Widget sectionHeader({required String label});

  /// Large pixel-art avatar block — centerpiece of the home page.
  Widget avatar({required String avatarKey, required String displayName, String? subtitle});

  /// Daily XP bar. Tappable when `onTap` is non-null (used to open the
  /// breakdown view).
  Widget xpBar({
    required int earned,
    required int goal,
    required double progress,
    VoidCallback? onTap,
  });

  /// Body of the XP breakdown view (rendered inline within the home tab).
  Widget xpBreakdownSheet({
    required int earned,
    required int goal,
    required List<XpGain> items,
  });

  /// One quest tile in the picker. Mode = active (tap to remove) or available
  /// (tap to add, disabled if active list is full).
  Widget questPickerTile({
    required Quest quest,
    required bool isActive,
    required bool canActivate,
    required VoidCallback onTap,
  });

  /// One row in the friends leaderboard.
  Widget friendRow({
    required Friend friend,
    required bool isCurrentUser,
    required VoidCallback onTap,
  });

  /// Header at the top of the friend-detail view.
  Widget friendDetailHeader({required FriendDetail friend});

  /// One row in the friend's last-7-days XP history list.
  Widget friendDailyXpRow({required DailyXp entry, required bool isToday});
}
