import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment, MedicationDose;
import 'package:migraine_forecast/data/repos/medication_repo.dart';

void main() {
  late AppDatabase db;
  late MedicationRepo repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = MedicationRepo(db);
  });
  tearDown(() => db.close());

  final now = DateTime.utc(2026, 7, 11, 12);

  test('insert + recent round-trip preserves class and rating', () async {
    await repo.insert(MedicationDose(
        at: now.subtract(const Duration(days: 1)),
        name: 'Sumatriptan',
        medClass: MedClass.triptan));
    await repo.insert(MedicationDose(
        at: now.subtract(const Duration(days: 2)),
        name: 'Ibuprofen',
        medClass: MedClass.simpleAnalgesic,
        reliefRating: 2));

    final doses = await repo.recent(window: const Duration(days: 90), now: now);
    expect(doses, hasLength(2));
    expect(doses.first.name, 'Sumatriptan'); // most recent first
    expect(doses.first.medClass, MedClass.triptan);
    expect(doses.first.reliefRating, isNull);
    expect(doses.last.reliefRating, 2);
  });

  test('recent excludes doses outside the window', () async {
    await repo.insert(MedicationDose(
        at: now.subtract(const Duration(days: 120)),
        name: 'Old',
        medClass: MedClass.other));
    expect(await repo.recent(window: const Duration(days: 90), now: now), isEmpty);
  });

  test('setRelief updates an existing dose', () async {
    final id = await repo.insert(MedicationDose(
        at: now, name: 'Sumatriptan', medClass: MedClass.triptan));
    await repo.setRelief(id, 1);
    final doses = await repo.recent(window: const Duration(days: 1), now: now);
    expect(doses.single.reliefRating, 1);
  });

  test('distinctNames returns unique names, most recent first', () async {
    await repo.insert(MedicationDose(
        at: now.subtract(const Duration(days: 3)),
        name: 'Ibuprofen',
        medClass: MedClass.simpleAnalgesic));
    await repo.insert(MedicationDose(
        at: now.subtract(const Duration(days: 2)),
        name: 'Sumatriptan',
        medClass: MedClass.triptan));
    await repo.insert(MedicationDose(
        at: now.subtract(const Duration(days: 1)),
        name: 'Ibuprofen',
        medClass: MedClass.simpleAnalgesic));
    expect(await repo.distinctNames(), ['Ibuprofen', 'Sumatriptan']);
  });
}
