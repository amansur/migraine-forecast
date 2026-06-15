import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:migraine_forecast/data/sources/oura_auth_manager.dart';
import 'package:migraine_forecast/data/sources/oura_oauth_flow.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockAuthManager extends Mock implements OuraAuthManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  const clientId = 'test_client_id';
  const clientSecret = 'test_client_secret';
  const redirectUri = 'com.migraine-forecast://oauth/callback';

  final validTokenBody = jsonEncode({
    'access_token': 'access_abc',
    'refresh_token': 'refresh_xyz',
    'expires_in': 86400,
  });

  final validPersonalInfoBody = jsonEncode({'email': 'user@example.com'});

  OuraOAuthFlow makeFlow({
    required MockHttpClient httpClient,
    required MockAuthManager authManager,
    required Future<String> Function(String) browserLauncher,
  }) {
    return OuraOAuthFlow(
      clientId: clientId,
      clientSecret: clientSecret,
      redirectUri: redirectUri,
      authManager: authManager,
      httpClient: httpClient,
      browserLauncher: browserLauncher,
    );
  }

  /// Builds a callback URL that matches the state returned by the browser launcher.
  /// The launcher receives the authorize URL and must embed the state in the callback.
  String buildCallbackWithState(String authorizeUrl, {String? overrideState}) {
    final uri = Uri.parse(authorizeUrl);
    final state = overrideState ?? uri.queryParameters['state']!;
    return '$redirectUri?code=authcode123&state=$state';
  }

  group('OuraOAuthFlow', () {
    late MockHttpClient mockHttp;
    late MockAuthManager mockAuth;

    setUp(() {
      mockHttp = MockHttpClient();
      mockAuth = MockAuthManager();
    });

    test('throws OuraOAuthException on state mismatch', () async {
      // Browser returns a callback with a different state value.
      final flow = makeFlow(
        httpClient: mockHttp,
        authManager: mockAuth,
        browserLauncher: (url) async =>
            '$redirectUri?code=authcode123&state=WRONG_STATE',
      );

      expect(() => flow.connect(), throwsA(isA<OuraOAuthException>()));
    });

    test('calls saveTokens with correct values on successful exchange',
        () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(validTokenBody, 200));

      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response(validPersonalInfoBody, 200));

      when(() => mockAuth.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
            expiresAt: any(named: 'expiresAt'),
            userEmail: any(named: 'userEmail'),
          )).thenAnswer((_) async {});

      final flow = makeFlow(
        httpClient: mockHttp,
        authManager: mockAuth,
        browserLauncher: (url) async => buildCallbackWithState(url),
      );

      await flow.connect();

      verify(() => mockAuth.saveTokens(
            accessToken: 'access_abc',
            refreshToken: 'refresh_xyz',
            expiresAt: any(named: 'expiresAt'),
            userEmail: 'user@example.com',
          )).called(1);
    });

    test('throws OuraOAuthException on token exchange HTTP failure', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('Unauthorized', 401));

      final flow = makeFlow(
        httpClient: mockHttp,
        authManager: mockAuth,
        browserLauncher: (url) async => buildCallbackWithState(url),
      );

      expect(() => flow.connect(), throwsA(isA<OuraOAuthException>()));
    });

    test('proceeds without email if personal info request fails', () async {
      when(() => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response(validTokenBody, 200));

      when(() => mockHttp.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Forbidden', 403));

      when(() => mockAuth.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
            expiresAt: any(named: 'expiresAt'),
            userEmail: any(named: 'userEmail'),
          )).thenAnswer((_) async {});

      final flow = makeFlow(
        httpClient: mockHttp,
        authManager: mockAuth,
        browserLauncher: (url) async => buildCallbackWithState(url),
      );

      await flow.connect();

      verify(() => mockAuth.saveTokens(
            accessToken: 'access_abc',
            refreshToken: 'refresh_xyz',
            expiresAt: any(named: 'expiresAt'),
            userEmail: null,
          )).called(1);
    });
  });
}
