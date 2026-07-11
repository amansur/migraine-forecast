import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

// Hide drift's generated row class; the domain MedicationDose is the
// currency of this repo (same pattern as Attack/JournalEntry elsewhere).
import '../database.dart' hide MedicationDose;

class MedicationRepo {
  final AppDatabase _db;
  MedicationRepo(this._db);

  Future<int> insert(MedicationDose d) =>
      _db.into(_db.medicationDoses).insert(MedicationDosesCompanion.insert(
          at: d.at,
          name: d.name,
          medClass: d.medClass.name,
          reliefRating: Value(d.reliefRating)));

  Future<void> setRelief(int id, int rating) =>
      (_db.update(_db.medicationDoses)..where((t) => t.id.equals(id)))
          .write(MedicationDosesCompanion(reliefRating: Value(rating)));

  Future<List<MedicationDose>> recent(
      {required Duration window, required DateTime now}) async {
    final rows = await (_db.select(_db.medicationDoses)
          ..where((t) => t.at.isBiggerOrEqualValue(now.subtract(window)))
          ..orderBy([(t) => OrderingTerm.desc(t.at)]))
        .get();
    return [
      for (final r in rows)
        MedicationDose(
            id: r.id,
            at: r.at,
            name: r.name,
            medClass: _parseClass(r.medClass),
            reliefRating: r.reliefRating),
    ];
  }

  Future<List<String>> distinctNames() async {
    final rows = await (_db.select(_db.medicationDoses)
          ..orderBy([(t) => OrderingTerm.desc(t.at)]))
        .get();
    final seen = <String>{};
    return [
      for (final r in rows)
        if (seen.add(r.name)) r.name,
    ];
  }

  /// Tolerant parse (imported backups may carry unknown class strings) —
  /// unknowns land in [MedClass.other] rather than crashing the med views.
  static MedClass _parseClass(String name) {
    for (final c in MedClass.values) {
      if (c.name == name) return c;
    }
    return MedClass.other;
  }
}
