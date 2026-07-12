import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repos/medication_repo.dart';
import 'providers.dart';

final medicationRepoProvider =
    Provider<MedicationRepo>((ref) => MedicationRepo(ref.watch(databaseProvider)));

final recentMedicationDosesProvider = FutureProvider<List<MedicationDose>>((ref) =>
    ref.watch(medicationRepoProvider)
        .recent(window: const Duration(days: 90), now: DateTime.now().toUtc()));

final medicationNamesProvider = FutureProvider<List<String>>(
    (ref) => ref.watch(medicationRepoProvider).distinctNames());

/// Rolling ICHD-3 medication-overuse status over the last 30 days of doses.
final mohStatusProvider = FutureProvider<MohStatus>((ref) async {
  final doses = await ref.watch(recentMedicationDosesProvider.future);
  return assessMoh(doses, DateTime.now().toUtc());
});
