import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/settings_repo.dart';

void main() {
  late AppDatabase db;
  late SettingsRepo repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = SettingsRepo(db);
  });
  tearDown(() => db.close());

  test('returns null for unset key', () async {
    expect(await repo.getString('display_mode'), isNull);
  });

  test('round-trips a string value', () async {
    await repo.setString('display_mode', 'gauge');
    expect(await repo.getString('display_mode'), 'gauge');
  });

  test('returns false for unset bool', () async {
    expect(await repo.getBool('notifications_enabled'), isFalse);
  });

  test('round-trips a bool', () async {
    await repo.setBool('notifications_enabled', true);
    expect(await repo.getBool('notifications_enabled'), isTrue);
  });
}
