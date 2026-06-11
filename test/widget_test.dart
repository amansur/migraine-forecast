// Basic smoke test: verify the app widget tree builds without errors.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:migraine_weatherr/app/app.dart';
import 'package:migraine_weatherr/data/database.dart';
import 'package:migraine_weatherr/state/providers.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MigraineWeatherrApp(),
      ),
    );
    // No assertion needed — if the pump throws, the test fails.
  });
}
