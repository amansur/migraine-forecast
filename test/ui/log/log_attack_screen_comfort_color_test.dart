import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/log/log_attack_screen.dart';

void main() {
  testWidgets('severity label uses onSurface color from ambient theme', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildComfortTheme(),
          home: const LogAttackScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labelFinder = find.textContaining('Severity:');
    expect(labelFinder, findsOneWidget);

    final BuildContext ctx = tester.element(labelFinder);
    final expected = Theme.of(ctx).colorScheme.onSurface;

    final Text widget = tester.widget(labelFinder);
    final TextStyle resolved =
        widget.style ?? DefaultTextStyle.of(ctx).style;
    final Color effective = resolved.color ?? DefaultTextStyle.of(ctx).style.color!;

    expect(effective, expected);
  });
}
