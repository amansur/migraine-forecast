import 'package:domain/domain.dart';
import 'package:test/test.dart';

DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

PeriodEvent _p(DateTime start, {DateTime? end, int baseline = 5}) =>
    PeriodEvent(startedAt: start, endedAt: end, baselineSeverity: baseline);

/// Asserts the phase regardless of confirmed/predicted wrapper.
({CyclePhase phase, int dayOfCycle}) _unwrap(PhaseResult r) {
  return switch (r) {
    PhaseConfirmed(:final phase, :final dayOfCycle) =>
      (phase: phase, dayOfCycle: dayOfCycle),
    PhasePredicted(:final phase, :final dayOfCycle) =>
      (phase: phase, dayOfCycle: dayOfCycle),
    PhaseUnknown() => throw StateError('unknown phase'),
  };
}

void main() {
  group('meanCycleLength', () {
    test('null with fewer than 2 periods', () {
      expect(meanCycleLength(const []), isNull);
      expect(meanCycleLength([_p(_d(2026, 1, 1))]), isNull);
    });

    test('mean of consecutive gaps', () {
      final periods = [
        _p(_d(2026, 1, 1)),
        _p(_d(2026, 1, 29)),
        _p(_d(2026, 2, 26)),
      ];
      expect(meanCycleLength(periods), 28);
    });

    test('mean-of-last-6 ignores older cycles', () {
      final starts = <DateTime>[_d(2026, 1, 1)];
      for (var i = 0; i < 4; i++) {
        starts.add(starts.last.add(const Duration(days: 40)));
      }
      for (var i = 0; i < 6; i++) {
        starts.add(starts.last.add(const Duration(days: 28)));
      }
      final periods = starts.map((s) => _p(s)).toList();
      expect(meanCycleLength(periods), 28);
    });

    test('rounds to nearest int', () {
      final periods = [
        _p(_d(2026, 1, 1)),
        _p(_d(2026, 1, 29)), // 28
        _p(_d(2026, 2, 25)), // 27
        _p(_d(2026, 3, 25)), // 28
      ];
      expect(meanCycleLength(periods), 28);
    });
  });

  group('phaseFor — unknown', () {
    test('no periods', () {
      expect(phaseFor(_d(2026, 6, 1), periods: const [], overrides: const []),
          isA<PhaseUnknown>());
    });

    test('one period -> still unknown (no cycle length yet)', () {
      final r = phaseFor(
        _d(2026, 6, 1),
        periods: [_p(_d(2026, 5, 1), end: _d(2026, 5, 5))],
        overrides: const [],
      );
      expect(r, isA<PhaseUnknown>());
    });

    test('day before any logged period -> unknown', () {
      final periods = [
        _p(_d(2026, 5, 1), end: _d(2026, 5, 5)),
        _p(_d(2026, 5, 29)),
      ];
      expect(phaseFor(_d(2026, 4, 1), periods: periods, overrides: const []),
          isA<PhaseUnknown>());
    });
  });

  group('phaseFor — 28-day cycle, day anchored by NON-latest start (Confirmed)', () {
    // Anchor cycle: 2026-04-03 → next start 2026-05-01 → length 28.
    // Days within [2026-04-03, 2026-04-30] are bounded by two observed
    // starts, so they should be Confirmed.
    final periods = [
      _p(_d(2026, 4, 3), end: _d(2026, 4, 7)), // menses days 1..5
      _p(_d(2026, 5, 1), end: _d(2026, 5, 5)),
    ];

    test('day 1 -> menses', () {
      final r = phaseFor(_d(2026, 4, 3), periods: periods, overrides: const []);
      expect(r, isA<PhaseConfirmed>());
      expect(_unwrap(r), (phase: CyclePhase.menses, dayOfCycle: 1));
    });

    test('day 5 -> menses (last menses day)', () {
      final r = phaseFor(_d(2026, 4, 7), periods: periods, overrides: const []);
      expect(_unwrap(r).phase, CyclePhase.menses);
    });

    test('day 6 -> follicular', () {
      final r = phaseFor(_d(2026, 4, 8), periods: periods, overrides: const []);
      expect(r, isA<PhaseConfirmed>());
      expect(_unwrap(r).phase, CyclePhase.follicular);
    });

    test('day 12 -> follicular (last follicular)', () {
      final r = phaseFor(_d(2026, 4, 14), periods: periods, overrides: const []);
      expect(_unwrap(r).phase, CyclePhase.follicular);
    });

    test('day 13 -> ovulatory (first ovulatory)', () {
      final r = phaseFor(_d(2026, 4, 15), periods: periods, overrides: const []);
      expect(_unwrap(r).phase, CyclePhase.ovulatory);
    });

    test('day 16 -> ovulatory (last ovulatory)', () {
      final r = phaseFor(_d(2026, 4, 18), periods: periods, overrides: const []);
      expect(_unwrap(r).phase, CyclePhase.ovulatory);
    });

    test('day 17 -> luteal (first luteal)', () {
      final r = phaseFor(_d(2026, 4, 19), periods: periods, overrides: const []);
      expect(_unwrap(r).phase, CyclePhase.luteal);
    });

    test('day 28 -> luteal (last day before next start)', () {
      final r = phaseFor(_d(2026, 4, 30), periods: periods, overrides: const []);
      expect(_unwrap(r).phase, CyclePhase.luteal);
    });
  });

  group('phaseFor — anchored by latest start -> Predicted', () {
    final periods = [
      _p(_d(2026, 4, 3), end: _d(2026, 4, 7)),
      _p(_d(2026, 5, 1), end: _d(2026, 5, 5)),
    ];

    test('day inside the projected cycle -> Predicted', () {
      // 2026-05-10 = day 10 of the projected cycle starting 2026-05-01.
      final r = phaseFor(_d(2026, 5, 10), periods: periods, overrides: const []);
      expect(r, isA<PhasePredicted>());
      expect(_unwrap(r).phase, CyclePhase.follicular);
    });

    test('day 1 of latest period -> Predicted (anchor IS latest)', () {
      final r = phaseFor(_d(2026, 5, 1), periods: periods, overrides: const []);
      expect(r, isA<PhasePredicted>());
      expect(_unwrap(r), (phase: CyclePhase.menses, dayOfCycle: 1));
    });
  });

  group('phaseFor — in-progress period (null endedAt)', () {
    test('menses defaults to day 5 when no endedAt', () {
      final periods = [
        _p(_d(2026, 4, 3), end: _d(2026, 4, 7)),
        _p(_d(2026, 5, 1)), // ongoing
      ];
      expect(_unwrap(phaseFor(_d(2026, 5, 3), periods: periods, overrides: const [])).phase,
          CyclePhase.menses);
      expect(_unwrap(phaseFor(_d(2026, 5, 5), periods: periods, overrides: const [])).phase,
          CyclePhase.menses);
      expect(_unwrap(phaseFor(_d(2026, 5, 6), periods: periods, overrides: const [])).phase,
          CyclePhase.follicular);
    });
  });

  group('phaseFor — 31-day cycle boundaries', () {
    // Two 31-day gaps -> mean 31. Anchor: 2026-03-31 (non-latest -> Confirmed).
    // menses: 1..5, follicular: 6..15, ovulatory: 16..19, luteal: 20..31
    final periods = [
      _p(_d(2026, 2, 28), end: _d(2026, 3, 4)),
      _p(_d(2026, 3, 31), end: _d(2026, 4, 4)),
      _p(_d(2026, 5, 1), end: _d(2026, 5, 5)),
    ];

    test('day 15 -> follicular', () {
      expect(_unwrap(phaseFor(_d(2026, 4, 14), periods: periods, overrides: const [])).phase,
          CyclePhase.follicular);
    });

    test('day 16 -> ovulatory', () {
      expect(_unwrap(phaseFor(_d(2026, 4, 15), periods: periods, overrides: const [])).phase,
          CyclePhase.ovulatory);
    });

    test('day 19 -> ovulatory', () {
      expect(_unwrap(phaseFor(_d(2026, 4, 18), periods: periods, overrides: const [])).phase,
          CyclePhase.ovulatory);
    });

    test('day 20 -> luteal', () {
      expect(_unwrap(phaseFor(_d(2026, 4, 19), periods: periods, overrides: const [])).phase,
          CyclePhase.luteal);
    });
  });
}
