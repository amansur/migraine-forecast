import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

QueryExecutor nativeMemoryDatabase() => NativeDatabase.memory();

/// Renames the legacy `migraine_weatherr.sqlite` to `migraine_forecast.sqlite`
/// on first launch after the filename change. No-op if the old file doesn't
/// exist or the new file is already present.
Future<void> renameLegacyDbFile() async {
  try {
    final docs = await getApplicationDocumentsDirectory();
    final oldFile = File('${docs.path}/migraine_weatherr.sqlite');
    final newFile = File('${docs.path}/migraine_forecast.sqlite');
    if (oldFile.existsSync() && !newFile.existsSync()) {
      await oldFile.rename(newFile.path);
    }
  } catch (_) {
    // Best-effort: if rename fails, drift will create a fresh DB.
  }
}
