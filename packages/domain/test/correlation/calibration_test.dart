import 'package:domain/domain.dart';
import 'package:test/test.dart';

DayRecord scored(int d, int score, RiskBand band,
        {bool attack = false, bool backfilled = false}) =>
    DayRecord(
        day: DateTime.utc(2026, 6, d),
        score: score,
        band: band,
        hadAttack: attack,
        backfilled: backfilled);

void main() {
  test('groups observed attack rate per band with Wilson CIs and Brier score', () {
    final days = [
      scored(1, 10, RiskBand.low),
      scored(2, 15, RiskBand.low),
      scored(3, 80, RiskBand.veryHigh, attack: true),
      scored(4, 85, RiskBand.veryHigh),
      DayRecord(day: DateTime.utc(2026, 6, 5)), // unscored → excluded
    ];

    final r = analyzeCalibration(days);
    expect(r.scoredDays, 4);
    expect(r.bands.length, 2);
    expect(r.bands.first.band, RiskBand.low);
    expect(r.bands.first.attackRate.point, 0);
    expect(r.bands.first.days, 2);
    expect(r.bands.last.band, RiskBand.veryHigh);
    expect(r.bands.last.attackRate.point, 0.5);
    // Brier: mean of (0.1-0)^2, (0.15-0)^2, (0.8-1)^2, (0.85-0)^2
    expect(r.brierScore, closeTo((0.01 + 0.0225 + 0.04 + 0.7225) / 4, 1e-9));
  });

  test('excludes backfilled days by default, includes them on request', () {
    final days = [
      scored(1, 80, RiskBand.veryHigh, attack: true, backfilled: true),
      scored(2, 20, RiskBand.low),
    ];
    expect(analyzeCalibration(days).scoredDays, 1);
    expect(analyzeCalibration(days, includeBackfilled: true).scoredDays, 2);
  });

  test('empty input yields null Brier and no bands', () {
    final r = analyzeCalibration(const []);
    expect(r.brierScore, isNull);
    expect(r.bands, isEmpty);
    expect(r.scoredDays, 0);
  });
}
