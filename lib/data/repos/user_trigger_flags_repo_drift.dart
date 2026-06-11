import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../context_builder.dart' show UserTriggerFlagsRepo;
import '../database.dart';

class UserTriggerFlagsRepoDrift implements UserTriggerFlagsRepo {
  final AppDatabase _db;
  UserTriggerFlagsRepoDrift(this._db);

  @override
  Future<UserTriggerFlags> load() async {
    final rows = await _db.select(_db.userTriggerFlagsTbl).get();
    final flagged = <String>{};
    final overrides = <String, double>{};
    for (final r in rows) {
      if (r.flagged) flagged.add(r.moduleId);
      if (r.weightOverride != 0) overrides[r.moduleId] = r.weightOverride;
    }
    return UserTriggerFlags(flaggedModuleIds: flagged, weightOverrides: overrides);
  }

  @override
  Future<void> save(UserTriggerFlags flags) async {
    await _db.transaction(() async {
      await _db.delete(_db.userTriggerFlagsTbl).go();
      for (final id in flags.flaggedModuleIds) {
        await _db.into(_db.userTriggerFlagsTbl).insert(
              UserTriggerFlagsTblCompanion.insert(
                moduleId: id,
                flagged: const Value(true),
                weightOverride: Value(flags.weightOverrides[id] ?? 0),
              ),
            );
      }
      for (final entry in flags.weightOverrides.entries) {
        if (flags.flaggedModuleIds.contains(entry.key)) continue;
        await _db.into(_db.userTriggerFlagsTbl).insert(
              UserTriggerFlagsTblCompanion.insert(
                moduleId: entry.key,
                flagged: const Value(false),
                weightOverride: Value(entry.value),
              ),
            );
      }
    });
  }
}
