import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

// `watchRecentAttacks` uses a strict `startedAt < now` upper bound that is
// baked into the Drift WHERE clause at subscription time. If we pass the
// literal current instant, attacks logged moments later are excluded even
// though the stream re-emits on insert. Pad the upper bound generously so
// "log right now" and late-evening sessions crossing midnight still hit
// the window.
DateTime _attackWindowUpperBound() =>
    DateTime.now().toUtc().add(const Duration(days: 2));

/// True once the user has logged at least one attack. Used by router/UI to
/// gate the Insights tab.
final insightsEligibleProvider = StreamProvider<bool>((ref) {
  final journal = ref.watch(journalSourceProvider);
  return journal
      .watchRecentAttacks(const Duration(days: 365), now: _attackWindowUpperBound())
      .map((attacks) => attacks.isNotEmpty);
});

final attackCountProvider = StreamProvider<int>((ref) {
  final journal = ref.watch(journalSourceProvider);
  return journal
      .watchRecentAttacks(const Duration(days: 365), now: _attackWindowUpperBound())
      .map((attacks) => attacks.length);
});

final recentAttacksProvider = StreamProvider<List<Attack>>((ref) {
  final journal = ref.watch(journalSourceProvider);
  return journal.watchRecentAttacks(const Duration(days: 90), now: _attackWindowUpperBound());
});
