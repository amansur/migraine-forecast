import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/services/permission_service.dart';

void main() {
  test('locationGranted defaults to false', () {
    final svc = PermissionService.forTesting();
    expect(svc.locationGranted, isFalse);
  });

  test('markLocationGranted flips the flag', () {
    final svc = PermissionService.forTesting();
    svc.markLocationGranted();
    expect(svc.locationGranted, isTrue);
  });
}
