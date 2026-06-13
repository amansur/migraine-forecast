import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// True once the user has logged at least one attack. Used by router/UI to
/// gate the Insights tab.
final insightsEligibleProvider = StreamProvider<bool>((ref) {
  final journal = ref.watch(journalSourceProvider);
  return journal
      .watchRecentAttacks(const Duration(days: 365), now: DateTime.now().toUtc())
      .map((attacks) => attacks.isNotEmpty);
});

final attackCountProvider = StreamProvider<int>((ref) {
  final journal = ref.watch(journalSourceProvider);
  return journal
      .watchRecentAttacks(const Duration(days: 365), now: DateTime.now().toUtc())
      .map((attacks) => attacks.length);
});

final recentAttacksProvider = StreamProvider<List<Attack>>((ref) {
  final journal = ref.watch(journalSourceProvider);
  return journal.watchRecentAttacks(const Duration(days: 90), now: DateTime.now().toUtc());
});
