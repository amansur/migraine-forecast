import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// True once the user has logged ≥3 attacks. Used by router/UI to gate the
/// Insights tab.
final insightsEligibleProvider = FutureProvider<bool>((ref) async {
  final journal = ref.watch(journalSourceProvider);
  final attacks = await journal.recentAttacks(const Duration(days: 365), now: DateTime.now().toUtc());
  return attacks.length >= 3;
});

final attackCountProvider = FutureProvider<int>((ref) async {
  final journal = ref.watch(journalSourceProvider);
  final attacks = await journal.recentAttacks(const Duration(days: 365), now: DateTime.now().toUtc());
  return attacks.length;
});
