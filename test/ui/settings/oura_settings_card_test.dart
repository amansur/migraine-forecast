import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:migraine_forecast/data/sources/oura_auth_manager.dart';
import 'package:migraine_forecast/data/sources/oura_oauth_flow.dart';
import 'package:migraine_forecast/state/oura_settings_provider.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/settings/oura_settings_card.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockOuraAuthManager extends Mock implements OuraAuthManager {}

class MockOuraOAuthFlow extends Mock implements OuraOAuthFlow {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a ProviderScope that wires [authState] directly into
/// [ouraAuthStateProvider] (bypassing the real notifier's async init).
Widget _buildCard({
  required OuraAuthState authState,
  OuraOAuthFlow? oAuthFlow,
}) {
  final mockFlow = oAuthFlow ?? MockOuraOAuthFlow();

  return ProviderScope(
    overrides: [
      // Override the StateNotifierProvider with a fixed initial state.
      ouraAuthStateProvider.overrideWith(
        (ref) {
          final mockManager = MockOuraAuthManager();
          when(() => mockManager.isAuthenticated)
              .thenReturn(authState.authenticated);
          when(() => mockManager.userEmail).thenReturn(authState.email);
          when(() => mockManager.initialize()).thenAnswer((_) async {});
          when(() => mockManager.logout()).thenAnswer((_) async {});
          return OuraAuthStateNotifier(mockManager);
        },
      ),
      ouraOAuthFlowProvider.overrideWithValue(mockFlow),
    ],
    child: const MaterialApp(
      home: Scaffold(body: OuraSettingsCard()),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('OuraSettingsCard', () {
    testWidgets('not connected — shows Connect button and "Not connected" subtitle',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(authState: OuraAuthState.unauthenticated),
      );
      await tester.pump(); // allow _initialize() microtask to settle

      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Not connected'), findsOneWidget);
    });

    testWidgets('connected without email — shows Disconnect and "Connected" subtitle',
        (tester) async {
      await tester.pumpWidget(
        _buildCard(
          authState: const OuraAuthState(authenticated: true),
        ),
      );
      await tester.pump();

      expect(find.text('Disconnect'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('connected with email — shows email as subtitle', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          authState: const OuraAuthState(
            authenticated: true,
            email: 'user@example.com',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Disconnect'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('radio group visible when connected', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          authState: const OuraAuthState(authenticated: true),
        ),
      );
      await tester.pump();

      expect(find.text('Data Source Preference'), findsOneWidget);
    });

    testWidgets('radio group hidden when not connected', (tester) async {
      await tester.pumpWidget(
        _buildCard(authState: OuraAuthState.unauthenticated),
      );
      await tester.pump();

      expect(find.text('Data Source Preference'), findsNothing);
    });

    testWidgets('tapping Connect invokes connect()',
        (tester) async {
      final mockFlow = MockOuraOAuthFlow();
      when(() => mockFlow.connect()).thenAnswer((_) async {});

      late OuraAuthStateNotifier capturedNotifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ouraAuthStateProvider.overrideWith((ref) {
              final mockManager = MockOuraAuthManager();
              when(() => mockManager.isAuthenticated).thenReturn(false);
              when(() => mockManager.userEmail).thenReturn(null);
              when(() => mockManager.initialize()).thenAnswer((_) async {});
              final notifier = OuraAuthStateNotifier(mockManager);
              capturedNotifier = notifier;
              return notifier;
            }),
            ouraOAuthFlowProvider.overrideWithValue(mockFlow),
          ],
          child: const MaterialApp(home: Scaffold(body: OuraSettingsCard())),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      verify(() => mockFlow.connect()).called(1);
    });

    testWidgets('OAuth error shows SnackBar with error message', (tester) async {
      final mockFlow = MockOuraOAuthFlow();
      when(() => mockFlow.connect())
          .thenThrow(Exception('network error'));

      await tester.pumpWidget(
        _buildCard(
          authState: OuraAuthState.unauthenticated,
          oAuthFlow: mockFlow,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('network error'), findsOneWidget);
    });
  });
}
