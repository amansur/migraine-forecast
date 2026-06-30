// Basic smoke test: verify the app widget tree builds without errors.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:migraine_forecast/app/app.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/state/providers.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        // disableAnimations stops the mascot idle-loop timer from running.
        child: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MigraineForecastApp(),
        ),
      ),
    );
    // No assertion needed — if the pump throws, the test fails.
    //
    // Replace the app with an empty widget to trigger ProviderScope disposal.
    // Drift schedules a zero-duration timer when stream subscriptions are
    // cancelled; running the disposal inside runAsync lets that timer fire on
    // the real event loop, avoiding the framework's "pending timer" failure.
    await tester.runAsync(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(Duration.zero);
    });
  });
}
