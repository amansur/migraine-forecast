import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/checkin_repo.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  test('record then read back; unanswered day is null; re-record replaces', () async {
    final repo = CheckinRepo(db);
    final day = DateTime.utc(2026, 7, 8);
    expect(await repo.forDay(day), isNull);
    await repo.record(day: day, hadAttack: false, at: DateTime.utc(2026, 7, 9, 9));
    expect((await repo.forDay(day))!.hadAttack, isFalse);
    await repo.record(day: day, hadAttack: true, at: DateTime.utc(2026, 7, 9, 10));
    expect((await repo.forDay(day))!.hadAttack, isTrue);
  });
}
