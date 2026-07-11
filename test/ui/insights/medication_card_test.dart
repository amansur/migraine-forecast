import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/medication_provider.dart';
import 'package:migraine_forecast/ui/insights/medication_card.dart';

MedicationDose _dose(int day, {int? relief, String name = 'Sumatriptan'}) =>
    MedicationDose(
        at: DateTime.utc(2026, 7, day, 10),
        name: name,
        medClass: MedClass.triptan,
        reliefRating: relief);

void main() {
  Widget host(List<MedicationDose> doses, MohStatus moh) => ProviderScope(
        overrides: [
          recentMedicationDosesProvider.overrideWith((ref) async => doses),
          mohStatusProvider.overrideWith((ref) async => moh),
        ],
        child: const MaterialApp(home: Scaffold(body: MedicationCard())),
      );

  testWidgets('shows ICHD-3 warning when threshold exceeded', (tester) async {
    const moh = MohStatus(
        level: MohLevel.exceeded,
        medClass: MedClass.triptan,
        daysUsed: 10,
        thresholdDays: 10);
    await tester.pumpWidget(host(const [], moh));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('moh-warning')), findsOneWidget);
    expect(find.textContaining('10 of the last 30 days'), findsOneWidget);
    expect(find.textContaining('ICHD-3'), findsOneWidget);
  });

  testWidgets('shows efficacy line for names with 3+ rated doses', (tester) async {
    final doses = [
      _dose(1, relief: 2),
      _dose(2, relief: 2),
      _dose(3, relief: 0),
      _dose(4), // unrated — excluded from the count
      _dose(5, relief: 1, name: 'Ibuprofen'), // only 1 rated — hidden
    ];
    await tester.pumpWidget(host(doses, const MohStatus(level: MohLevel.none)));
    await tester.pumpAndSettle();
    expect(find.text('Sumatriptan — helped 2 of 3 times'), findsOneWidget);
    expect(find.textContaining('Ibuprofen'), findsNothing);
  });

  testWidgets('hidden with no warning and no rated doses', (tester) async {
    await tester.pumpWidget(host(const [], const MohStatus(level: MohLevel.none)));
    await tester.pumpAndSettle();
    expect(find.text('Medications'), findsNothing);
  });
}
