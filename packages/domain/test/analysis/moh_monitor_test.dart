import 'package:domain/domain.dart';
import 'package:test/test.dart';

// Local noon: assessMoh bins by local calendar day, so local-constructed
// times keep these tests timezone-independent.
MedicationDose dose(int day, MedClass c, {String name = 'x'}) => MedicationDose(
    at: DateTime(2026, 6, day, 12), name: name, medClass: c);

void main() {
  final now = DateTime(2026, 6, 30, 18);

  test('10 distinct triptan days in 30d → exceeded (ICHD-3)', () {
    final doses = [for (var d = 1; d <= 10; d++) dose(d, MedClass.triptan)];
    final s = assessMoh(doses, now);
    expect(s.level, MohLevel.exceeded);
    expect(s.medClass, MedClass.triptan);
    expect(s.daysUsed, 10);
    expect(s.thresholdDays, 10);
  });

  test('8 triptan days → approaching (80% of threshold)', () {
    final doses = [for (var d = 1; d <= 8; d++) dose(d, MedClass.triptan)];
    expect(assessMoh(doses, now).level, MohLevel.approaching);
  });

  test('7 triptan days → none', () {
    final doses = [for (var d = 1; d <= 7; d++) dose(d, MedClass.triptan)];
    expect(assessMoh(doses, now).level, MohLevel.none);
  });

  test('simple analgesics use the 15-day threshold; two doses same day count once',
      () {
    final doses = [
      for (var d = 1; d <= 12; d++) dose(d, MedClass.simpleAnalgesic),
      dose(1, MedClass.simpleAnalgesic, name: 'second-same-day'),
    ];
    final s = assessMoh(doses, now);
    expect(s.daysUsed, 12);
    expect(s.level, MohLevel.approaching); // ceil(0.8*15)=12
  });

  test('preventives and doses outside 30d are ignored', () {
    final doses = [
      for (var d = 1; d <= 20; d++) dose(d, MedClass.preventive),
      MedicationDose(
          at: DateTime.utc(2026, 4, 1), name: 'old', medClass: MedClass.triptan),
    ];
    expect(assessMoh(doses, now).level, MohLevel.none);
  });

  test('worst class wins across classes', () {
    final doses = [
      for (var d = 1; d <= 10; d++) dose(d, MedClass.triptan),
      for (var d = 1; d <= 12; d++) dose(d, MedClass.simpleAnalgesic, name: 'ibu'),
    ];
    final s = assessMoh(doses, now);
    expect(s.level, MohLevel.exceeded);
    expect(s.medClass, MedClass.triptan);
  });
}
