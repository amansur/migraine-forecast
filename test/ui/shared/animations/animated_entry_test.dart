import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/shared/animations/animated_entry.dart';

void main() {
  testWidgets('renders child instantly under reduced motion (no transitions)', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedEntry(child: Text('HELLO')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('HELLO'), findsOneWidget);
    expect(find.byType(SlideTransition), findsNothing);
    expect(find.byType(FadeTransition), findsNothing);
  });

  testWidgets('animates in with slide+fade when motion enabled', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedEntry(child: Text('HELLO')),
    ));
    expect(find.byType(SlideTransition), findsOneWidget);
    expect(find.byType(FadeTransition), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('HELLO'), findsOneWidget);
  });

  testWidgets('scalePop effect uses ScaleTransition', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedEntry(effect: AnimatedEntryEffect.scalePop, child: Text('CHIP')),
    ));
    expect(find.byType(ScaleTransition), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
