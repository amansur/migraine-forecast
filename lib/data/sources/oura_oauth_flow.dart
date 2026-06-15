import 'dart:convert';
import 'dart:math';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import 'oura_auth_manager.dart';

/// Thrown when the OAuth flow fails for any reason.
class OuraOAuthException implements Exception {
  OuraOAuthException(this.message);
  final String message;

  @override
  String toString() => 'OuraOAuthException: $message';
}

/// Handles the full Oura Ring OAuth 2.0 authorization code flow.
class OuraOAuthFlow {
  OuraOAuthFlow({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    required this.authManager,
    http.Client? httpClient,
    Future<String> Function(String authorizeUrl)? browserLauncher,
  })  : _httpClient = httpClient ?? http.Client(),
        _browserLauncher = browserLauncher ??
            ((url) => FlutterWebAuth2.authenticate(
                  url: url,
                  callbackUrlScheme: 'com.migraine-forecast',
                ));

  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final OuraAuthManager authManager;
  final http.Client _httpClient;
  final Future<String> Function(String authorizeUrl) _browserLauncher;

  static const _authBaseUrl = 'https://cloud.ouraring.com/oauth/authorize';
  static const _tokenUrl = 'https://api.ouraring.com/oauth/token';
  static const _personalInfoUrl =
      'https://api.ouraring.com/v2/usercollection/personal_info';

  String _generateState() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Launches the browser, lets the user grant access, exchanges the
  /// authorization code for tokens, and persists them via [authManager.saveTokens].
  ///
  /// Throws [OuraOAuthException] on cancellation, state mismatch, or token
  /// exchange failure.
  Future<void> connect() async {
    final state = _generateState();

    final authorizeUrl = Uri.parse(_authBaseUrl).replace(queryParameters: {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'email personal daily heartrate session sleep tag workout',
      'state': state,
    }).toString();

    final String resultUrl;
    try {
      resultUrl = await _browserLauncher(authorizeUrl);
    } catch (e) {
      throw OuraOAuthException('Browser authentication cancelled or failed: $e');
    }

    final resultUri = Uri.parse(resultUrl);
    final returnedState = resultUri.queryParameters['state'];
    if (returnedState != state) {
      throw OuraOAuthException('state mismatch');
    }

    final code = resultUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw OuraOAuthException('No authorization code in callback URL');
    }

    // Exchange code for tokens.
    final tokenResponse = await _httpClient.post(
      Uri.parse(_tokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
      },
    );

    if (tokenResponse.statusCode != 200) {
      throw OuraOAuthException(
          'Token exchange failed with status ${tokenResponse.statusCode}: ${tokenResponse.body}');
    }

    final Map<String, dynamic> tokenData;
    try {
      tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
    } catch (e) {
      throw OuraOAuthException('Failed to parse token response: $e');
    }

    final accessToken = tokenData['access_token'] as String?;
    final refreshToken = tokenData['refresh_token'] as String?;
    final expiresIn = tokenData['expires_in'];

    if (accessToken == null || refreshToken == null || expiresIn == null) {
      throw OuraOAuthException('Token response missing required fields');
    }

    final expiresAt = DateTime.now().add(
      Duration(seconds: (expiresIn as num).toInt()),
    );

    // Optionally fetch user email — failure is non-fatal.
    String? userEmail;
    try {
      final infoResponse = await _httpClient.get(
        Uri.parse(_personalInfoUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (infoResponse.statusCode == 200) {
        final info =
            jsonDecode(infoResponse.body) as Map<String, dynamic>;
        userEmail = info['email'] as String?;
      }
    } catch (_) {
      // Proceed without email.
    }

    await authManager.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      userEmail: userEmail,
    );
  }
}
