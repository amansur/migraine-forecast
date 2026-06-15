import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/oura_auth_manager.dart';
import 'providers.dart';

/// StateNotifier for managing Oura authentication state
class OuraAuthStateNotifier extends StateNotifier<bool> {
  final OuraAuthManager manager;

  OuraAuthStateNotifier(this.manager) : super(false) {
    _initialize();
  }

  /// Initialize by loading stored authentication state
  Future<void> _initialize() async {
    await manager.initialize();
    state = manager.isAuthenticated;
  }

  /// Handle user logout
  Future<void> logout() async {
    await manager.logout();
    state = false;
  }

  /// Set authentication credentials after OAuth callback
  Future<void> setAuthenticated(String token, String email) async {
    await manager.setAccessToken(token);
    await manager.setUserEmail(email);
    state = true;
  }
}

/// StateNotifierProvider for tracking Oura authentication state
final ouraAuthStateProvider =
    StateNotifierProvider<OuraAuthStateNotifier, bool>((ref) {
  final manager = ref.watch(ouraAuthManagerProvider);
  return OuraAuthStateNotifier(manager);
});

/// Provider for current Oura user email
final ouraUserEmailProvider = Provider<String?>((ref) {
  final manager = ref.watch(ouraAuthManagerProvider);
  return manager.userEmail;
});
