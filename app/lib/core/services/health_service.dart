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

  /// Whether HealthKit has granted us read access for *all* v1 types.
  /// Returns null on iOS for unknown state (Apple intentionally hides this).
  Future<bool?> hasAllPermissions() async {
    await _ready;
    return _h.hasPermissions(v1HealthTypes, permissions: v1HealthPermissions);
  }

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

  /// Reads samples between [start] and [end] (exclusive of [end]).
  Future<List<HealthDataPoint>> fetchRange({
    required DateTime start,
    required DateTime end,
  }) async {
    await _ready;
    final points = await _h.getHealthDataFromTypes(
      types: v1HealthTypes,
      startTime: start,
      endTime: end,
    );
    return _h.removeDuplicates(points);
  }

  /// Converts a [HealthDataPoint] to the JSON shape backend expects.
  /// Returns null for points whose value isn't a simple number.
  static Map<String, dynamic>? toSampleJson(HealthDataPoint p) {
    final value = p.value;
    if (value is! NumericHealthValue) return null;
    return {
      'type': p.type.name,
      'value': value.numericValue.toDouble(),
      'unit': p.unit.name,
      'start_date': p.dateFrom.toUtc().toIso8601String(),
      'end_date': p.dateTo.toUtc().toIso8601String(),
      'source': p.sourceName,
      'device': p.sourceDeviceId,
    };
  }
}
