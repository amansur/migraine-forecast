import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bulk_backfill_orchestrator.dart';
import 'correlation_provider.dart';
import 'insights_eligibility_provider.dart';
import 'providers.dart';

/// Holds the live progress of an in-flight backfill (done, total), or null
/// when no backfill is running. The Insights screen subscribes to this to
/// show a progress strip above the heatmap.
final backfillProgressProvider =
    StateProvider<({int done, int total})?>((_) => null);

/// Holds the most recent completed [BackfillReport], or null if no backfill
/// has finished in this session. The Insights screen surfaces this when
/// daysFailed > 0 so the user knows the heatmap is incomplete.
final lastBackfillReportProvider =
    StateProvider<BackfillReport?>((_) => null);

/// Module-level guard. The orchestrator's own `_running` flag is per-instance,
/// but [launchBackfill] constructs a new orchestrator on every call, so the
/// real concurrency check has to live here.
bool _backfillRunning = false;

/// Starts a backfill run fire-and-forget style. Safe to call multiple times;
/// concurrent calls return immediately.
///
/// Takes a [ProviderContainer] rather than a `WidgetRef` so the caller can
/// outlive the widget that triggered it (e.g. onboarding navigates away the
/// same frame it kicks off backfill).
///
/// On completion, invalidates the providers that the heatmap and correlation
/// cards depend on.
Future<void> launchBackfill(
  ProviderContainer container, {
  bool wipeExisting = false,
}) async {
  debugPrint('launchBackfill: invoked (running=$_backfillRunning, wipe=$wipeExisting)');
  if (_backfillRunning) return;
  _backfillRunning = true;
  if (wipeExisting) {
    final n = await container.read(assessmentRepoProvider).deleteAllBackfilled();
    debugPrint('launchBackfill: cleared $n backfilled assessments');
  }
  // Show the ribbon immediately so the user sees feedback during the prime
  // weather fetch (which runs before the first per-day onProgress callback).
  container.read(backfillProgressProvider.notifier).state = (done: 0, total: 0);
  debugPrint('launchBackfill: progress state set to (0,0)');
  try {
    final config = await container.read(rulesConfigProvider.future);
    debugPrint('launchBackfill: rulesConfig loaded');

    final orchestrator = BulkBackfillOrchestrator(
      contextBuilder: container.read(contextBuilderProvider),
      riskEngine: container.read(riskEngineProvider),
      rulesConfig: config,
      assessmentRepo: container.read(assessmentRepoProvider),
      locationSource: container.read(locationSourceProvider),
      weatherSource: container.read(weatherSourceProvider),
    );

    debugPrint('launchBackfill: orchestrator.run() starting');
    final report = await orchestrator.run(
      onProgress: (done, total) {
        if (done == 1 || done == total || done % 10 == 0) {
          debugPrint('launchBackfill: onProgress $done / $total');
        }
        container.read(backfillProgressProvider.notifier).state =
            (done: done, total: total);
      },
    );
    debugPrint('launchBackfill: orchestrator.run() returned '
        'processed=${report.daysProcessed} skipped=${report.daysSkipped} '
        'failed=${report.daysFailed} weatherOk=${report.weatherFetchSucceeded}');

    container.read(backfillProgressProvider.notifier).state = null;
    container.read(lastBackfillReportProvider.notifier).state = report;

    if (report.daysProcessed > 0) {
      container.invalidate(correlationResultsProvider);
      container.invalidate(recentAttacksProvider);
      container.invalidate(dayAssessmentProvider);
    }
  } catch (e, st) {
    debugPrint('launchBackfill: threw $e\n$st');
    container.read(backfillProgressProvider.notifier).state = null;
    rethrow;
  } finally {
    _backfillRunning = false;
    debugPrint('launchBackfill: done');
  }
}
