import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/repos/user_trigger_flags_repo_drift.dart';

void main() {
  late AppDatabase db;
  late UserTriggerFlagsRepoDrift repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = UserTriggerFlagsRepoDrift(db);
  });
  tearDown(() => db.close());

  test('empty store returns empty flags', () async {
    final loaded = await repo.load();
    expect(loaded.flaggedModuleIds, isEmpty);
    expect(loaded.weightOverrides, isEmpty);
  });

  test('round-trips flags and overrides', () async {
    await repo.save(const UserTriggerFlags(
      flaggedModuleIds: {'pressure_drop', 'sleep_deficit'},
      weightOverrides: {'pressure_drop': 1.0, 'alcohol': -1.0},
    ));
    final loaded = await repo.load();
    expect(loaded.flaggedModuleIds, {'pressure_drop', 'sleep_deficit'});
    expect(loaded.weightOverrides, {'pressure_drop': 1.0, 'alcohol': -1.0});
  });

  test('save replaces prior state (no leftovers)', () async {
    await repo.save(const UserTriggerFlags(flaggedModuleIds: {'a', 'b'}));
    await repo.save(const UserTriggerFlags(flaggedModuleIds: {'c'}));
    final loaded = await repo.load();
    expect(loaded.flaggedModuleIds, {'c'});
  });
}
