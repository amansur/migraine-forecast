import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment, MedicationDose;
import 'package:migraine_forecast/data/repos/medication_repo.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/ui/log/medication_entry_sheet.dart';

void main() {
  Widget host(AppDatabase db) => ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: MedicationEntrySheet()))),
      );

  testWidgets('saves a dose with name, class, and relief rating', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await tester.pumpWidget(host(db));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(find.byKey(const Key('med-save'))).onPressed,
        isNull); // disabled until valid

    await tester.enterText(find.byKey(const Key('med-name')), 'Sumatriptan');
    await tester.tap(find.byKey(const Key('med-class-triptan')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('med-relief-2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('med-save')));
    await tester.pumpAndSettle();

    final doses = await MedicationRepo(db)
        .recent(window: const Duration(days: 1), now: DateTime.now().toUtc());
    expect(doses, hasLength(1));
    expect(doses.single.name, 'Sumatriptan');
    expect(doses.single.medClass, MedClass.triptan);
    expect(doses.single.reliefRating, 2);
  });

  testWidgets('past names appear as tappable chips that fill the field',
      (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await MedicationRepo(db).insert(MedicationDose(
        at: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        name: 'Ibuprofen',
        medClass: MedClass.simpleAnalgesic));

    await tester.pumpWidget(host(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('med-past-Ibuprofen')));
    await tester.pump();
    expect(
        tester.widget<TextField>(find.byKey(const Key('med-name'))).controller!.text,
        'Ibuprofen');
  });
}
