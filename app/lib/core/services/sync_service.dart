import 'api_client.dart';
import 'health_service.dart';

class SyncOutcome {
  SyncOutcome({this.error});
  final Object? error;
  bool get ok => error == null;
}

/// Pushes the on-device daily summary (today's per-metric totals) to the
/// backend so quest progress + proportional XP stay current. No raw samples
/// are uploaded or stored anywhere — HealthKit is the source of truth.
///
/// Triggered on launch and by the native HealthKit background observer when
/// new data lands. Totals are idempotent, so there's no retry queue: a failed
/// push is simply superseded by the next one.
class SyncService {
  SyncService({HealthService? health, ApiClient? api})
    : _health = health ?? HealthService(),
      _api = api ?? ApiClient();

  final HealthService _health;
  final ApiClient _api;

  /// In-flight de-duplication: collapses the burst of HKObserverQuery
  /// callbacks on launch into one round-trip.
  Future<SyncOutcome>? _inFlight;

  Future<SyncOutcome> syncOnce() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final fresh = _doSyncOnce();
    _inFlight = fresh;
    fresh.whenComplete(() {
      if (identical(_inFlight, fresh)) _inFlight = null;
    });
    return fresh;
  }

  Future<SyncOutcome> _doSyncOnce() async {
    try {
      final totals = await _health.computeTodayTotals();
      // Ongoing/observer syncs only push progress (totals). The pool is
      // generated from the 7-day baseline at app launch (AppShell), so we
      // send an empty baseline here.
      await _api.syncQuests(baselines: const {}, totals: totals);
      return SyncOutcome();
    } catch (e) {
      return SyncOutcome(error: e);
    }
  }
}
