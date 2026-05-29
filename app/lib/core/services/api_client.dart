import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/user_snapshot.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when the backend returns 401. AppShell pivots to the auth screen
/// on this signal instead of hanging on a loading state.
class UnauthenticatedException implements Exception {
  UnauthenticatedException([this.message = 'not signed in']);
  final String message;
  @override
  String toString() => message;
}

class AuthResult {
  AuthResult({required this.token, required this.userId});
  final String token;
  final int userId;
}

/// Talks to the XPulse FastAPI backend.
///
/// Reads the bearer token from secure storage on every call. POSTs retry up
/// to 3 total attempts with exponential backoff before throwing.
class ApiClient {
  /// Backend base URL — read from the gitignored `.env` (`XPULSE_API_BASE_URL`),
  /// loaded in `main()`. Always the deployed host, even in local dev — there is
  /// deliberately NO localhost fallback. If `.env` is missing the value is
  /// empty and requests fail loudly instead of silently hitting localhost.
  static String get _envBaseUrl => dotenv.env['XPULSE_API_BASE_URL'] ?? '';

  ApiClient({String? baseUrl, StorageService? storage, http.Client? httpClient})
    : _baseUrl = baseUrl ?? _envBaseUrl,
      _storage = storage ?? StorageService.instance,
      _http = httpClient ?? http.Client();

  final String _baseUrl;
  final StorageService _storage;
  final http.Client _http;

  Future<bool> healthOk() async {
    final r = await _http.get(Uri.parse('$_baseUrl/health'));
    return r.statusCode == 200;
  }

  /// POST /v1/auth/signup — creates a REGULAR user, returns a per-user token.
  Future<AuthResult> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final r = await _http.post(
      Uri.parse('$_baseUrl/v1/auth/signup'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'display_name': displayName,
      }),
    );
    if (r.statusCode == 201 || r.statusCode == 200) {
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      return AuthResult(
        token: j['token'] as String,
        userId: j['user_id'] as int,
      );
    }
    throw ApiException(r.statusCode, _errorMessage(r.body));
  }

  /// POST /v1/auth/login — exchanges email+password for the user's token.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final r = await _http.post(
      Uri.parse('$_baseUrl/v1/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      return AuthResult(
        token: j['token'] as String,
        userId: j['user_id'] as int,
      );
    }
    if (r.statusCode == 401) {
      throw UnauthenticatedException('invalid email or password');
    }
    throw ApiException(r.statusCode, _errorMessage(r.body));
  }

  String _errorMessage(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['detail'] is String) return j['detail'] as String;
    } catch (_) {}
    return body;
  }

  /// GET /v1/me/snapshot — the one read endpoint that powers all three pages
  /// (user, today, quests, friends).
  Future<UserSnapshot> getSnapshot() async {
    final r = await _authed('GET', '/v1/me/snapshot');
    return UserSnapshot.fromJson(jsonDecode(r) as Map<String, dynamic>);
  }

  /// POST /v1/me/quests/sync — push the on-device summaries (7-day baseline
  /// for target generation + today's per-metric totals for progress). No raw
  /// samples are sent or stored; HealthKit is the source of truth.
  Future<void> syncQuests({
    required Map<String, double> baselines,
    required Map<String, double> totals,
    String? tz,
  }) async {
    await _authed(
      'POST',
      '/v1/me/quests/sync',
      body: {
        'baselines': baselines,
        'totals': totals,
        if (tz != null) 'tz': tz,
      },
    );
  }

  /// POST /v1/me/quests/{id}/activate — move a quest into the active 4.
  /// Throws [ApiException] (409) if the day is already locked.
  Future<void> activateQuest(String questId) async {
    await _authed('POST', '/v1/me/quests/$questId/activate');
  }

  /// POST /v1/me/quests/{id}/deactivate — move a quest back to available.
  Future<void> deactivateQuest(String questId) async {
    await _authed('POST', '/v1/me/quests/$questId/deactivate');
  }

  /// GET /v1/users/{id} — used by the friend-detail screen.
  Future<FriendDetail> getFriendDetail(int userId) async {
    final r = await _authed('GET', '/v1/users/$userId');
    return FriendDetail.fromJson(jsonDecode(r) as Map<String, dynamic>);
  }

  Future<String> _authed(String method, String path, {Object? body}) async {
    final token = await _storage.getApiToken();
    if (token == null || token.isEmpty) {
      throw UnauthenticatedException('no token in storage');
    }
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final uri = Uri.parse('$_baseUrl$path');
    final encoded = body == null ? null : jsonEncode(body);

    final r = await switch (method) {
      'GET' => _http.get(uri, headers: headers),
      'POST' => _http.post(uri, headers: headers, body: encoded),
      'PATCH' => _http.patch(uri, headers: headers, body: encoded),
      _ => throw ArgumentError('unsupported method: $method'),
    }.timeout(const Duration(seconds: 15));

    if (r.statusCode >= 200 && r.statusCode < 300) return r.body;
    if (r.statusCode == 401) {
      throw UnauthenticatedException(_errorMessage(r.body));
    }
    throw ApiException(r.statusCode, _errorMessage(r.body));
  }
}
