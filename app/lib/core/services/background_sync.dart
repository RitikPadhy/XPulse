import 'package:flutter/services.dart';

import 'sync_service.dart';

/// Bridges native HealthKit observer callbacks → Dart sync.
///
/// iOS Swift side registers HKObserverQuery + enableBackgroundDelivery for
/// each sample type. When HealthKit notifies the app of new data, the
/// observer fires and posts "syncRequested" on this channel. We respond by
/// running [SyncService.syncOnce]. Background launches use the same path.
class BackgroundSync {
  static const _channel = MethodChannel('xpulse/background_sync');
  static bool _registered = false;
  static SyncService? _service;

  /// Wires the Dart-side handler. Safe to call multiple times — idempotent.
  static void register(SyncService service) {
    _service = service;
    if (_registered) return;
    _registered = true;
    _channel.setMethodCallHandler(_onCall);
  }

  static Future<dynamic> _onCall(MethodCall call) async {
    if (call.method == 'syncRequested') {
      final s = _service;
      if (s == null) return false;
      try {
        final outcome = await s.syncOnce();
        return outcome.ok;
      } catch (_) {
        return false;
      }
    }
    return null;
  }

  /// Asks native (iOS only) to register HKObserverQuery + enable background
  /// delivery for all v1 types. Call after HealthKit permissions are granted.
  static Future<void> startObservers() async {
    try {
      await _channel.invokeMethod('startObservers');
    } catch (_) {
      // Channel not implemented (Android) — no-op
    }
  }
}
