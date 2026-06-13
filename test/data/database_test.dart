import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';

void main() {
  test('in-memory database opens and accepts a journal entry', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await db.into(db.journalEntries).insert(JournalEntriesCompanion.insert(
          at: DateTime.utc(2026, 6, 10, 8),
          kind: 'alcohol',
          payloadJson: '{"units": 2.0}',
        ));

    final rows = await db.select(db.journalEntries).get();
    expect(rows, hasLength(1));
    expect(rows.first.kind, 'alcohol');
  });
}
