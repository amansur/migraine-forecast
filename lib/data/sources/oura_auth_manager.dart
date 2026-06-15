import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OuraAuthManager {
  static const _storageKeyAccessToken = 'oura_access_token';
  static const _storageKeyRefreshToken = 'oura_refresh_token';
  static const _storageKeyUserEmail = 'oura_user_email';

  final FlutterSecureStorage storage;

  OuraAuthManager({FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage();

  bool get isAuthenticated => _cachedAccessToken != null;
  String? get userEmail => _cachedUserEmail;

  String? _cachedAccessToken;
  String? _cachedUserEmail;

  /// Initialize by loading stored token from secure storage
  Future<void> initialize() async {
    _cachedAccessToken = await storage.read(key: _storageKeyAccessToken);
    _cachedUserEmail = await storage.read(key: _storageKeyUserEmail);
  }

  /// Set access token (called after OAuth callback)
  Future<void> setAccessToken(String token) async {
    _cachedAccessToken = token;
    await storage.write(key: _storageKeyAccessToken, value: token);
  }

  /// Set refresh token (called after OAuth callback)
  Future<void> setRefreshToken(String token) async {
    await storage.write(key: _storageKeyRefreshToken, value: token);
  }

  /// Set user email (called after OAuth callback)
  Future<void> setUserEmail(String email) async {
    _cachedUserEmail = email;
    await storage.write(key: _storageKeyUserEmail, value: email);
  }

  /// Get valid access token (refresh if needed)
  Future<String?> getValidAccessToken() async {
    return _cachedAccessToken;
  }

  /// Logout and clear all tokens
  Future<void> logout() async {
    _cachedAccessToken = null;
    _cachedUserEmail = null;
    await storage.delete(key: _storageKeyAccessToken);
    await storage.delete(key: _storageKeyRefreshToken);
    await storage.delete(key: _storageKeyUserEmail);
  }
}
