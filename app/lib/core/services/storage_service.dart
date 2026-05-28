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
  static const _ownedMarkerKey = 'xpulse.storage_owned';

  final _secure = const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Call once at app startup, before anything reads the token.
  ///
  /// iOS Keychain entries survive app deletion by default — that means a
  /// stranger reinstalling the app on the same phone would pick up the
  /// previous user's session. We anchor "did this install put the token
  /// there?" in SharedPreferences (which IS cleared on uninstall). Missing
  /// marker = fresh install, so we wipe any leftover Keychain entries.
  Future<void> ensureFreshInstallIsClean() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_ownedMarkerKey) == true) return;
    await _secure.deleteAll();
    await prefs.setBool(_ownedMarkerKey, true);
  }

  Future<String?> getApiToken() => _secure.read(key: _tokenKey);

  Future<void> setApiToken(String token) async {
    await _secure.write(key: _tokenKey, value: token);
    // Defensive: also (re-)write the marker every time we save a token, so
    // even if something cleared SharedPreferences mid-session we don't
    // accidentally wipe the live token on the next launch.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ownedMarkerKey, true);
  }

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
