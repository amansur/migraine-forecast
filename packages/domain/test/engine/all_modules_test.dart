import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('allTriggerModules is the single registry with unique, expected ids', () {
    final ids = [for (final m in allTriggerModules()) m.id];
    expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
    expect(ids, containsAll([
      'pressure_drop',
      'humidity',
      'temp_swing',
      'air_quality',
      'sleep_deficit',
      'hrv_letdown',
      'menstrual_phase',
      'refractory',
      'alcohol',
      'caffeine',
      'stress',
      'hydration',
      'intraday_pressure_swing',
      'skipped_meals',
      'wind',
    ]));
    expect(ids, hasLength(15));
  });
}
