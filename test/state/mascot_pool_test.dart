import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/mascot_pool.dart';

void main() {
  test('every band has at least one mascot', () {
    for (final band in RiskBand.values) {
      expect(kMascotPool[band], isNotEmpty, reason: '$band pool empty');
    }
  });

  test('all pooled paths look like mascot PNG assets', () {
    for (final paths in kMascotPool.values) {
      for (final p in paths) {
        expect(p, startsWith('assets/mascots/'));
        expect(p, endsWith('.png'));
      }
    }
  });

  test('same date and band always picks the same asset', () {
    final d = DateTime(2026, 7, 6, 9, 30);
    final later = DateTime(2026, 7, 6, 23, 59);
    for (final band in RiskBand.values) {
      expect(mascotAssetFor(band, date: d), mascotAssetFor(band, date: later));
    }
  });

  test('pick is always a member of the band pool', () {
    for (final band in RiskBand.values) {
      for (var day = 1; day <= 28; day++) {
        final pick = mascotAssetFor(band, date: DateTime(2026, 7, day));
        expect(kMascotPool[band], contains(pick));
      }
    }
  });

  test('picks vary across dates for bands with multiple options', () {
    final picks = <String>{
      for (var day = 1; day <= 28; day++)
        mascotAssetFor(RiskBand.low, date: DateTime(2026, 7, day)),
    };
    expect(picks.length, greaterThan(1));
  });

  test('allMascotAssetPaths is deduped and covers every pool entry', () {
    final all = allMascotAssetPaths();
    expect(all.toSet().length, all.length);
    for (final paths in kMascotPool.values) {
      for (final p in paths) {
        expect(all, contains(p));
      }
    }
  });
}
