import 'package:drift/drift.dart';

QueryExecutor nativeMemoryDatabase() {
  throw UnsupportedError('NativeDatabase.memory() is not supported on web');
}

/// No-op on web; the legacy filename only ever existed on native platforms.
Future<void> renameLegacyDbFile() async {}
