import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final triggerFlagsProvider = FutureProvider<UserTriggerFlags>((ref) async {
  return ref.watch(flagsRepoProvider).load();
});

final saveTriggerFlagsProvider = Provider<Future<void> Function(UserTriggerFlags)>((ref) {
  return (flags) async {
    await ref.read(flagsRepoProvider).save(flags);
    ref.invalidate(triggerFlagsProvider);
  };
});
