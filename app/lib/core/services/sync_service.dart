import 'api_client.dart';
import 'health_service.dart';
import 'storage_service.dart';

class SyncOutcome {
  SyncOutcome({
    required this.fetched,
    required this.posted,
    required this.inserted,
    required this.duplicates,
    required this.queued,
    this.error,
  });

  final int fetched;
  final int posted;
  final int inserted;
  final int duplicates;
  final int queued;
  final Object? error;

  bool get ok => error == null;
}

/// Drives a single sync pass: HealthKit query → POST → persist anchor.
///
/// Behavior on failure: the inline retry happens inside [ApiClient]; if all
/// three attempts fail, the batch is appended to a local queue and retried
/// at the start of the next sync. The `last_sync_at` timestamp is only
/// advanced after a successful POST so HealthKit re-queries the same range
/// on the next attempt (backend's UniqueConstraint absorbs the overlap).
class SyncService {
  SyncService({HealthService? health, ApiClient? api, StorageService? storage})
    : _health = health ?? HealthService(),
      _api = api ?? ApiClient(),
      _storage = storage ?? StorageService.instance;

  final HealthService _health;
  final ApiClient _api;
  final StorageService _storage;

  /// Look-back window when no previous sync has happened.
  static const _initialLookback = Duration(days: 1);

  /// In-flight de-duplication. If [syncOnce] is called while another sync is
  /// already running, the caller gets the *same* Future back instead of
  /// firing a second POST. This is what collapses the ~10 HKObserverQuery
  /// callbacks that fire in a burst on app launch into one round-trip.
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
    final now = DateTime.now();
    final since =
        (await _storage.getLastSyncAt()) ?? now.subtract(_initialLookback);

    // Drain queue first so old failures don't get stuck behind a new batch.
    final queued = await _storage.readQueue();

    final points = await _health.fetchRange(start: since, end: now);
    final fresh = <Map<String, dynamic>>[
      for (final p in points)
        if (HealthService.toSampleJson(p) case final j?) j,
    ];

    final batch = [...queued, ...fresh];

    try {
      final result = await _api.ingest(batch);
      await _storage.writeQueue(const []);
      await _storage.setLastSyncAt(now);
      return SyncOutcome(
        fetched: fresh.length,
        posted: batch.length,
        inserted: result.inserted,
        duplicates: result.duplicates,
        queued: 0,
      );
    } catch (e) {
      // Persist the full batch so next sync drains it. Don't advance anchor.
      await _storage.writeQueue(batch);
      return SyncOutcome(
        fetched: fresh.length,
        posted: 0,
        inserted: 0,
        duplicates: 0,
        queued: batch.length,
        error: e,
      );
    }
  }
}
