import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent state for the iOS app.
///
/// - API token → iOS Keychain via flutter_secure_storage
/// - "permissions asked" + fresh-install marker → shared_preferences
///
/// All methods are async; cache the instance and reuse it.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _tokenKey = 'xpulse.api_token';
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

  Future<bool> getPermissionsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permsAskedKey) ?? false;
  }

  Future<void> setPermissionsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permsAskedKey, true);
  }
}
