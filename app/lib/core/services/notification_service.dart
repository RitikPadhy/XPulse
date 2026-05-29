import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fitness-style local nudges tied to the daily XP bar.
///
/// Rules:
///  - One consistent message ("You've completed X% … come back to see!").
///  - At most 2 per day, fired at the 50% and 100% milestones of the daily
///    goal — event-driven, never on a fixed clock.
///  - Fired from the sync flow, so they only happen while the app is alive
///    (foreground, or background-woken by the HealthKit observer). A
///    force-quit app never fires one.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const _dateKey = 'xpulse.notif_date';
  static const _firedKey = 'xpulse.notif_fired'; // milestones fired today
  static const _milestones = <int>[50, 100]; // % of goal → max 2/day

  /// Initialize + request permission (the iOS prompt shows on first call).
  Future<void> init() async {
    if (_inited) return;
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(iOS: darwin),
    );
    _inited = true;
  }

  /// Call on every XP update. Fires a nudge when the user crosses a milestone
  /// not yet hit today, capped at 2/day. Safe to call repeatedly.
  Future<void> maybeNotifyProgress({
    required int earned,
    required int goal,
  }) async {
    if (goal <= 0) return;
    // NEVER notify while the app is on-screen. Only fire when it's actually
    // backgrounded (in recent apps / woken by the HealthKit observer).
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != AppLifecycleState.paused &&
        lifecycle != AppLifecycleState.hidden) {
      return;
    }
    await init();

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString(_dateKey) != today) {
      await prefs.setString(_dateKey, today);
      await prefs.setStringList(_firedKey, const []);
    }
    final fired = (prefs.getStringList(_firedKey) ?? [])
        .map(int.parse)
        .toSet();
    if (fired.length >= _milestones.length) return; // already maxed today

    final pct = (earned / goal * 100).floor();
    // Highest milestone crossed but not yet fired.
    int? toFire;
    for (final m in _milestones) {
      if (pct >= m && !fired.contains(m)) toFire = m;
    }
    if (toFire == null) return;

    fired.add(toFire);
    await prefs.setStringList(
      _firedKey,
      fired.map((e) => e.toString()).toList(),
    );

    // present* = false → never shows as a banner while the app is foreground
    // (defense-in-depth; we already bail out above when not backgrounded).
    // Background delivery shows the notification regardless of these flags.
    const darwin = DarwinNotificationDetails(
      presentAlert: false,
      presentBanner: false,
      presentSound: false,
    );
    await _plugin.show(
      id: toFire, // stable id per milestone/day
      title: 'XPulse',
      body: "You've completed $toFire% of today's goal — come back to see!",
      notificationDetails: const NotificationDetails(iOS: darwin),
    );
  }
}
