import 'package:domain/domain.dart';

// Stable display order so contributor chips/rows don't reshuffle between days.
// Weather modules lead in the order pressure → temp → humidity.
const _moduleOrder = <String>[
  'pressure_drop',
  'temp_swing',
  'humidity',
  'air_quality',
  'sleep_deficit',
  'hrv_letdown',
  'menstrual_phase',
  'alcohol',
  'caffeine',
  'stress',
  'hydration',
];

int _orderIndex(String id) {
  final i = _moduleOrder.indexOf(id);
  return i == -1 ? _moduleOrder.length : i;
}

List<TriggerSignal> sortContributorsForDisplay(Iterable<TriggerSignal> contributors) {
  final list = contributors.toList()
    ..sort((a, b) {
      final cmp = _orderIndex(a.moduleId).compareTo(_orderIndex(b.moduleId));
      return cmp != 0 ? cmp : a.moduleId.compareTo(b.moduleId);
    });
  return list;
}
