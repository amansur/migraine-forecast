import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final lastRefreshAtProvider = FutureProvider<DateTime?>((ref) async {
  return ref.watch(assessmentRepoProvider).latestComputedAt();
});
