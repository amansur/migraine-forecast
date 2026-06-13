import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/notification_dedup_repo.dart';

void main() {
  late AppDatabase db;
  late NotificationDedupRepo repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = NotificationDedupRepo(db);
  });
  tearDown(() => db.close());

  final date = DateTime.utc(2026, 6, 11);
  final now = DateTime.utc(2026, 6, 11, 6);

  test('hasNotifiedFor is false initially', () async {
    expect(await repo.hasNotifiedFor(date: date, horizon: RiskHorizon.today, band: RiskBand.high), isFalse);
  });

  test('record then check returns true', () async {
    await repo.record(date: date, horizon: RiskHorizon.today, band: RiskBand.high, at: now);
    expect(await repo.hasNotifiedFor(date: date, horizon: RiskHorizon.today, band: RiskBand.high), isTrue);
  });

  test('different horizons are tracked independently', () async {
    await repo.record(date: date, horizon: RiskHorizon.today, band: RiskBand.high, at: now);
    expect(await repo.hasNotifiedFor(date: date, horizon: RiskHorizon.tomorrow, band: RiskBand.high), isFalse);
  });

  test('different bands are tracked independently (escalating high → very_high should re-notify)', () async {
    await repo.record(date: date, horizon: RiskHorizon.today, band: RiskBand.high, at: now);
    expect(await repo.hasNotifiedFor(date: date, horizon: RiskHorizon.today, band: RiskBand.veryHigh), isFalse);
  });
}
