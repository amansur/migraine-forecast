import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/state/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('activeAttackProvider emits false initially, true when inProgress attack exists, false after clearing', () async {
    final db = AppDatabase.memory();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final stream = container.read(activeAttackProvider.stream);
    final values = <bool>[];
    final sub = stream.listen(values.add);
    addTearDown(sub.cancel);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(values, [false]);

    final id = await db.into(db.attacks).insert(AttacksCompanion.insert(
      startedAt: DateTime.now().toUtc(),
      severity: 7,
      inProgress: const Value(true),
    ));

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(values.last, true);

    await (db.update(db.attacks)..where((t) => t.id.equals(id))).write(
      AttacksCompanion(inProgress: const Value(false)),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(values.last, false);
  });
}
