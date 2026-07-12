import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repos/checkin_repo.dart';
import 'insights_eligibility_provider.dart';
import 'providers.dart';

final checkinRepoProvider =
    Provider<CheckinRepo>((ref) => CheckinRepo(ref.watch(databaseProvider)));

/// Yesterday's local-day key when we should ask "did yesterday's high-risk
/// day bring a migraine?", else null. Asks only after high/veryHigh days,
/// once per day, and only when no attack was already logged for that day.
final checkinPromptProvider = FutureProvider<DateTime?>((ref) async {
  final attacks = await ref.watch(recentAttacksProvider.future);
  final now = DateTime.now();
  final yesterday =
      DateTime.utc(now.year, now.month, now.day).subtract(const Duration(days: 1));

  final ass = await ref
      .watch(assessmentRepoProvider)
      .latestForDate(target: yesterday, horizon: RiskHorizon.today);
  if (ass == null) return null;
  if (ass.band != RiskBand.high && ass.band != RiskBand.veryHigh) return null;

  final attackYesterday = attacks.any((a) {
    final local = a.startedAt.toLocal();
    return DateTime.utc(local.year, local.month, local.day) == yesterday;
  });
  if (attackYesterday) return null;

  if (await ref.watch(checkinRepoProvider).forDay(yesterday) != null) return null;
  return yesterday;
});
