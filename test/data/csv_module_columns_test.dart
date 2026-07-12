import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/repos/csv_module_columns.dart';

void main() {
  test('csvModuleColumns covers every engine module', () {
    final registryIds = allTriggerModules().map((m) => m.id).toSet();
    final missing = registryIds.difference(csvModuleColumns.toSet());
    expect(missing, isEmpty,
        reason: 'Modules without CSV columns are silently dropped from '
            'risk-assessment exports and lost on CSV round-trip. Append the '
            'missing ids to csvModuleColumns.');
  });

  test('csvModuleColumns has no ids the engine does not know', () {
    final registryIds = allTriggerModules().map((m) => m.id).toSet();
    final unknown = csvModuleColumns.toSet().difference(registryIds);
    expect(unknown, isEmpty,
        reason: 'Stale column ids would emit empty columns forever; remove '
            'them or fix the typo.');
  });
}
