import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/oura_auth_manager.dart';
import '../data/sources/oura_oauth_flow.dart';
import 'providers.dart';

/// Immutable snapshot of Oura authentication state.
class OuraAuthState {
  final bool authenticated;
  final String? email;

  const OuraAuthState({required this.authenticated, this.email});

  OuraAuthState copyWith({bool? authenticated, String? email}) => OuraAuthState(
        authenticated: authenticated ?? this.authenticated,
        email: email ?? this.email,
      );

  static const unauthenticated = OuraAuthState(authenticated: false);
}

/// StateNotifier for managing Oura authentication state
class OuraAuthStateNotifier extends StateNotifier<OuraAuthState> {
  final OuraAuthManager manager;

  OuraAuthStateNotifier(this.manager) : super(OuraAuthState.unauthenticated) {
    _initialize();
  }

  /// Initialize by loading stored authentication state
  Future<void> _initialize() async {
    await manager.initialize();
    state = OuraAuthState(
      authenticated: manager.isAuthenticated,
      email: manager.userEmail,
    );
  }

  /// Handle user logout
  Future<void> logout() async {
    await manager.logout();
    state = OuraAuthState.unauthenticated;
  }

  /// Re-reads authentication state from the manager and updates [state].
  /// Call this after a successful OAuth flow to reflect the new auth status.
  Future<void> refreshFromManager() async {
    state = OuraAuthState(
      authenticated: manager.isAuthenticated,
      email: manager.userEmail,
    );
  }
}

/// StateNotifierProvider for tracking Oura authentication state
final ouraAuthStateProvider =
    StateNotifierProvider<OuraAuthStateNotifier, OuraAuthState>((ref) {
  final manager = ref.watch(ouraAuthManagerProvider);
  return OuraAuthStateNotifier(manager);
});

/// Provider for the Oura OAuth flow.
final ouraOAuthFlowProvider = Provider<OuraOAuthFlow>((ref) {
  return OuraOAuthFlow(
    clientId: const String.fromEnvironment('OURA_CLIENT_ID'),
    clientSecret: const String.fromEnvironment('OURA_CLIENT_SECRET'),
    redirectUri: 'com.migraine-forecast://oauth/callback',
    authManager: ref.watch(ouraAuthManagerProvider),
  );
});
