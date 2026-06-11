// Basic smoke test: verify the app widget tree builds without errors.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:migraine_weatherr/app/app.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MigraineWeatherrApp()),
    );
    // No assertion needed — if the pump throws, the test fails.
  });
}
