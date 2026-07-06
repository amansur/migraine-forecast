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

  test('offset cycles within the band pool and wraps', () {
    final d = DateTime(2026, 7, 6);
    for (final band in RiskBand.values) {
      final pool = kMascotPool[band]!;
      final seen = <String>{
        for (var i = 0; i < pool.length; i++)
          mascotAssetFor(band, date: d, offset: i),
      };
      expect(seen.length, pool.length, reason: '$band: offsets must cover pool');
      expect(
        mascotAssetFor(band, date: d, offset: pool.length),
        mascotAssetFor(band, date: d),
        reason: '$band: offset == pool.length wraps to offset 0',
      );
    }
  });

  test('offset 0 matches the parameterless pick', () {
    final d = DateTime(2026, 7, 6);
    for (final band in RiskBand.values) {
      expect(mascotAssetFor(band, date: d, offset: 0),
          mascotAssetFor(band, date: d));
    }
  });

  test('wiggleStyleFor maps icons and defaults to squish', () {
    expect(wiggleStyleFor('assets/mascots/butterfly.png'), WiggleStyle.flutter);
    expect(wiggleStyleFor('assets/mascots/snail.png'), WiggleStyle.stretch);
    expect(wiggleStyleFor('assets/mascots/teacup.png'), WiggleStyle.bob);
    expect(wiggleStyleFor('assets/mascots/sun.png'), WiggleStyle.squish);
    expect(wiggleStyleFor('assets/mascots/unknown_thing.png'), WiggleStyle.squish);
  });

  test('every pooled icon resolves to a wiggle style without throwing', () {
    for (final p in allMascotAssetPaths()) {
      expect(() => wiggleStyleFor(p), returnsNormally);
    }
  });
}
