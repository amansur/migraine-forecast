import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/manual_sleep_provider.dart';
import 'package:migraine_forecast/ui/log/log_picker_sheet.dart';

Future<void> pump(WidgetTester tester, {required bool sleepEnabled}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [manualSleepEnabledProvider.overrideWithValue(sleepEnabled)],
    child: const MaterialApp(home: Scaffold(body: LogPickerSheet())),
  ));
}

void main() {
  testWidgets('shows 4 kinds when sleep is granted (manualSleepEnabled=false)',
      (tester) async {
    await pump(tester, sleepEnabled: false);
    expect(find.byKey(const Key('log-kind-alcohol')), findsOneWidget);
    expect(find.byKey(const Key('log-kind-caffeine')), findsOneWidget);
    expect(find.byKey(const Key('log-kind-hydration')), findsOneWidget);
    expect(find.byKey(const Key('log-kind-stress')), findsOneWidget);
    expect(find.byKey(const Key('log-kind-sleep')), findsNothing);
  });

  testWidgets('shows sleep when manualSleepEnabled=true', (tester) async {
    await pump(tester, sleepEnabled: true);
    expect(find.byKey(const Key('log-kind-sleep')), findsOneWidget);
  });

  testWidgets('always shows history link', (tester) async {
    await pump(tester, sleepEnabled: false);
    expect(find.byKey(const Key('log-history-link')), findsOneWidget);
  });
}
