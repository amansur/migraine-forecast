import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class OuraAuthManager {
  static const _storageKeyAccessToken = 'oura_access_token';
  static const _storageKeyRefreshToken = 'oura_refresh_token';
  static const _storageKeyUserEmail = 'oura_user_email';
  static const _storageKeyExpiresAt = 'oura_expires_at';

  static const String _tokenEndpoint = 'https://api.ouraring.com/oauth/token';

  // Read from --dart-define at compile time
  static const String _clientId =
      String.fromEnvironment('OURA_CLIENT_ID');
  static const String _clientSecret =
      String.fromEnvironment('OURA_CLIENT_SECRET');

  final FlutterSecureStorage storage;
  final http.Client _httpClient;

  OuraAuthManager({FlutterSecureStorage? storage, http.Client? httpClient})
      : storage = storage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? http.Client();

  bool get isAuthenticated => _cachedAccessToken != null;
  String? get userEmail => _cachedUserEmail;

  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedUserEmail;
  DateTime? _cachedExpiresAt;

  /// Initialize by loading stored tokens from secure storage.
  /// If secure storage is unavailable (e.g. unit tests without a platform
  /// channel mock), treat as logged out — don't propagate the failure.
  Future<void> initialize() async {
    try {
      _cachedAccessToken = await storage.read(key: _storageKeyAccessToken);
      _cachedRefreshToken = await storage.read(key: _storageKeyRefreshToken);
      _cachedUserEmail = await storage.read(key: _storageKeyUserEmail);
      final expiresAtStr = await storage.read(key: _storageKeyExpiresAt);
      if (expiresAtStr != null) {
        _cachedExpiresAt = DateTime.tryParse(expiresAtStr);
      }
    } catch (_) {
      // Secure storage unavailable; remain logged out.
    }
  }

  /// Save all token data atomically (primary method called after OAuth or refresh)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    String? userEmail,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    _cachedExpiresAt = expiresAt;
    if (userEmail != null) _cachedUserEmail = userEmail;

    await storage.write(key: _storageKeyAccessToken, value: accessToken);
    await storage.write(key: _storageKeyRefreshToken, value: refreshToken);
    await storage.write(key: _storageKeyExpiresAt, value: expiresAt.toIso8601String());
    if (userEmail != null) {
      await storage.write(key: _storageKeyUserEmail, value: userEmail);
    }
  }

  /// Get valid access token, refreshing if within 60 seconds of expiry
  Future<String?> getValidAccessToken() async {
    if (_cachedAccessToken == null) return null;

    final expiresAt = _cachedExpiresAt;
    final now = DateTime.now();

    // Token is fresh enough — return it directly
    if (expiresAt != null && expiresAt.isAfter(now.add(const Duration(seconds: 60)))) {
      return _cachedAccessToken;
    }

    // Token is missing expiry info or is near/past expiry — try to refresh
    return _refresh();
  }

  /// POST to Oura token endpoint with refresh_token grant
  Future<String?> _refresh() async {
    final refreshToken = _cachedRefreshToken;
    if (refreshToken == null) {
      await logout();
      return null;
    }

    try {
      final response = await _httpClient.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
      );

      if (response.statusCode != 200) {
        // Token genuinely rejected — clear session so user must re-authenticate.
        if (response.statusCode == 400 || response.statusCode == 401) {
          await logout();
        }
        // For transient errors (5xx, network, etc.) keep existing tokens and
        // let the next call retry rather than forcing re-authentication.
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String;
      final expiresIn = data['expires_in'] as int;
      final newExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      await saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        expiresAt: newExpiresAt,
      );

      return newAccessToken;
    } catch (_) {
      // Network or parse failure — keep tokens for next attempt.
      return null;
    }
  }

  /// Logout and clear all tokens
  Future<void> logout() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUserEmail = null;
    _cachedExpiresAt = null;
    await storage.delete(key: _storageKeyAccessToken);
    await storage.delete(key: _storageKeyRefreshToken);
    await storage.delete(key: _storageKeyUserEmail);
    await storage.delete(key: _storageKeyExpiresAt);
  }
}
