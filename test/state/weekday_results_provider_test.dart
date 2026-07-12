import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/correlation_provider.dart';

void main() {
  test('flags a weekday with concentrated attacks as personalHit', () async {
    final days = <DayRecord>[
      for (var i = 0; i < 56; i++)
        DayRecord(
          day: DateTime.utc(2026, 5, 4).add(Duration(days: i)), // 2026-05-04 is a Monday
          hadAttack: DateTime.utc(2026, 5, 4).add(Duration(days: i)).weekday ==
              DateTime.monday,
        ),
    ];
    final container = ProviderContainer(overrides: [
      dayTimelineProvider.overrideWith((ref) async => days),
    ]);
    addTearDown(container.dispose);
    final results = await container.read(weekdayResultsProvider.future);
    expect(results, hasLength(7));
    final monday = results.firstWhere((r) => r.exposureId == 'weekday_1');
    expect(monday.classification, CorrelationClassification.personalHit);
    expect(
        results
            .where((r) => r.classification == CorrelationClassification.personalHit),
        hasLength(1));
  });
}
