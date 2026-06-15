import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/oura_auth_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('OuraAuthManager', () {
    test('starts with no authentication', () async {
      final manager = OuraAuthManager(storage: MockSecureStorage());
      expect(manager.isAuthenticated, false);
      expect(manager.userEmail, null);
    });

    test('stores and retrieves access token', () async {
      final storage = MockSecureStorage();
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final manager = OuraAuthManager(storage: storage);
      await manager.setAccessToken('test-token');
      final token = await manager.getValidAccessToken();
      expect(token, 'test-token');
    });

    test('clears token on logout', () async {
      final storage = MockSecureStorage();
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => storage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final manager = OuraAuthManager(storage: storage);
      await manager.setAccessToken('test-token');
      await manager.logout();
      expect(manager.isAuthenticated, false);
    });
  });
}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
