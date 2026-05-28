import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent state for the iOS app.
///
/// - API token → iOS Keychain via flutter_secure_storage
/// - Last sync timestamp, retry queue → shared_preferences
///
/// All methods are async; cache the instance and reuse it.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _tokenKey = 'xpulse.api_token';
  static const _lastSyncKey = 'xpulse.last_sync_at';
  static const _queueKey = 'xpulse.retry_queue';
  static const _permsAskedKey = 'xpulse.permissions_asked';

  final _secure = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<String?> getApiToken() => _secure.read(key: _tokenKey);

  Future<void> setApiToken(String token) =>
      _secure.write(key: _tokenKey, value: token);

  Future<void> clearApiToken() => _secure.delete(key: _tokenKey);

  Future<DateTime?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastSyncAt(DateTime t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, t.toIso8601String());
  }

  /// Returns the raw JSON-serialized samples queued from prior failures.
  Future<List<Map<String, dynamic>>> readQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return [for (final s in decoded) Map<String, dynamic>.from(s as Map)];
  }

  Future<void> writeQueue(List<Map<String, dynamic>> samples) async {
    final prefs = await SharedPreferences.getInstance();
    if (samples.isEmpty) {
      await prefs.remove(_queueKey);
    } else {
      await prefs.setString(_queueKey, jsonEncode(samples));
    }
  }

  /// Wipes the sync anchor and any queued samples. Next sync will re-query
  /// the default look-back window (24h) from HealthKit. The API token is
  /// preserved.
  Future<void> resetSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
    await prefs.remove(_queueKey);
  }

  Future<bool> getPermissionsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permsAskedKey) ?? false;
  }

  Future<void> setPermissionsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permsAskedKey, true);
  }
}
