import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_snapshot.dart';
import 'storage_service.dart';

/// Result of a single ingest attempt.
class IngestResult {
  IngestResult({
    required this.received,
    required this.inserted,
    required this.duplicates,
  });

  final int received;
  final int inserted;
  final int duplicates;

  factory IngestResult.fromJson(Map<String, dynamic> j) => IngestResult(
        received: j['received'] as int,
        inserted: j['inserted'] as int,
        duplicates: j['duplicates'] as int,
      );
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Talks to the XPulse FastAPI backend.
///
/// Reads the bearer token from secure storage on every call. POSTs retry up
/// to 3 total attempts with exponential backoff before throwing.
class ApiClient {
  ApiClient({
    String baseUrl = 'http://129.159.228.56:8000',
    StorageService? storage,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _storage = storage ?? StorageService.instance,
        _http = httpClient ?? http.Client();

  final String _baseUrl;
  final StorageService _storage;
  final http.Client _http;

  static const _maxAttempts = 3;
  static const _baseBackoff = Duration(milliseconds: 500);

  Future<bool> healthOk() async {
    final r = await _http.get(Uri.parse('$_baseUrl/health'));
    return r.statusCode == 200;
  }

  /// GET /v1/me/snapshot — the one read endpoint that powers all three pages
  /// (user, today, quests, friends).
  Future<UserSnapshot> getSnapshot() async {
    final r = await _authed('GET', '/v1/me/snapshot');
    return UserSnapshot.fromJson(jsonDecode(r) as Map<String, dynamic>);
  }

  /// GET /v1/users/{id} — used by the friend-detail screen.
  Future<FriendDetail> getFriendDetail(int userId) async {
    final r = await _authed('GET', '/v1/users/$userId');
    return FriendDetail.fromJson(jsonDecode(r) as Map<String, dynamic>);
  }

  Future<String> _authed(String method, String path, {Object? body}) async {
    final token = await _storage.getApiToken();
    if (token == null || token.isEmpty) {
      throw ApiException(401, 'no api token configured');
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
    }
        .timeout(const Duration(seconds: 15));

    if (r.statusCode >= 200 && r.statusCode < 300) return r.body;
    throw ApiException(r.statusCode, r.body);
  }

  /// POST /v1/samples with retries. Throws [ApiException] after all attempts
  /// fail. The caller decides whether to queue or surface the error.
  Future<IngestResult> ingest(List<Map<String, dynamic>> samples) async {
    if (samples.isEmpty) {
      return IngestResult(received: 0, inserted: 0, duplicates: 0);
    }

    final token = await _storage.getApiToken();
    if (token == null || token.isEmpty) {
      throw ApiException(401, 'no api token configured');
    }

    final body = jsonEncode({'samples': samples});
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    Object? lastError;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final r = await _http
            .post(
              Uri.parse('$_baseUrl/v1/samples'),
              headers: headers,
              body: body,
            )
            .timeout(const Duration(seconds: 15));

        if (r.statusCode >= 200 && r.statusCode < 300) {
          return IngestResult.fromJson(
              jsonDecode(r.body) as Map<String, dynamic>);
        }

        // 4xx (other than 5xx) shouldn't be retried — caller's data/auth is wrong.
        if (r.statusCode >= 400 && r.statusCode < 500) {
          throw ApiException(r.statusCode, r.body);
        }
        lastError = ApiException(r.statusCode, r.body);
      } catch (e) {
        lastError = e;
      }

      if (attempt < _maxAttempts) {
        await Future.delayed(_baseBackoff * (1 << (attempt - 1)));
      }
    }

    if (lastError is ApiException) throw lastError;
    throw ApiException(0, 'network error: $lastError');
  }
}
