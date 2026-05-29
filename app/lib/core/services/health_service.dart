import 'package:health/health.dart';

import 'health_types.dart';

/// Wraps the `health` Dart package. Owns permission requests and incremental
/// queries against HealthKit.
class HealthService {
  HealthService() : _h = Health() {
    _ready = _h.configure();
  }

  final Health _h;
  late final Future<void> _ready;

  /// Triggers the iOS permission sheet for any types not yet granted.
  /// Returns true if the OS-level request completed (not "granted" — Apple
  /// won't tell us).
  Future<bool> requestPermissions() async {
    await _ready;
    return _h.requestAuthorization(
      v1HealthTypes,
      permissions: v1HealthPermissions,
    );
  }

  /// Per-metric 7-day baseline = median of daily totals, keyed by the
  /// HealthKit type name (matches the backend quest catalog metrics). Computed
  /// entirely on-device; only this summary is sent to the server — the raw
  /// history is never stored.
  Future<Map<String, double>> computeBaseline() async {
    await _ready;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final points = _h.removeDuplicates(
      await _h.getHealthDataFromTypes(
        types: v1HealthTypes,
        startTime: start,
        endTime: now,
      ),
    );

    // type -> (yyyy-mm-dd -> summed total that day)
    final byTypeDay = <String, Map<String, double>>{};
    for (final p in points) {
      final v = p.value;
      if (v is! NumericHealthValue) continue;
      final d = p.dateFrom.toLocal();
      final dayKey = '${d.year}-${d.month}-${d.day}';
      (byTypeDay[p.type.name] ??= {}).update(
        dayKey,
        (x) => x + v.numericValue.toDouble(),
        ifAbsent: () => v.numericValue.toDouble(),
      );
    }

    final out = <String, double>{};
    byTypeDay.forEach((type, days) {
      final totals = days.values.toList()..sort();
      if (totals.isEmpty) return;
      final mid = totals.length ~/ 2;
      final median = totals.length.isOdd
          ? totals[mid]
          : (totals[mid - 1] + totals[mid]) / 2;
      if (median > 0) out[type] = median;
    });
    return out;
  }

  /// Today's summed total per metric (local day), keyed by HealthKit type
  /// name. Sent to the server as progress — no raw samples leave the device.
  Future<Map<String, double>> computeTodayTotals() async {
    await _ready;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day); // local midnight
    final points = _h.removeDuplicates(
      await _h.getHealthDataFromTypes(
        types: v1HealthTypes,
        startTime: start,
        endTime: now,
      ),
    );
    final out = <String, double>{};
    for (final p in points) {
      final v = p.value;
      if (v is! NumericHealthValue) continue;
      out.update(
        p.type.name,
        (x) => x + v.numericValue.toDouble(),
        ifAbsent: () => v.numericValue.toDouble(),
      );
    }
    return out;
  }
}
