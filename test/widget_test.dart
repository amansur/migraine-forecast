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
    // Replace the app with an empty widget to trigger ProviderScope disposal,
    // then pump once to flush the zero-duration timer that Drift schedules when
    // stream subscriptions are cancelled. Without this the Flutter test
    // framework reports a "pending timer" invariant failure.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(); // fire the zero-duration Drift timer
    await tester.pump(); // drain any timers scheduled by that callback
  });
}
