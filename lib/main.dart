import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'services/background_scheduler.dart';
import 'services/notification_service.dart';

bool get _supportsLocalNotifications =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS);

bool get _supportsBackgroundScheduler =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid);

Future<void> _exportRulesConfigToDocs() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'rules_config_v1.json'));
    final bundled = await rootBundle.loadString('assets/rules_config_v1.json');
    await file.writeAsString(bundled);
  } catch (_) {
    // Web / unsupported — background scheduler is also unsupported on those
    // platforms, so silently skipping is fine.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _exportRulesConfigToDocs();
  if (_supportsLocalNotifications) {
    try {
      await NotificationService().init();
    } catch (_) {
      // Plugin missing in this environment — degrade silently.
    }
  }
  if (_supportsBackgroundScheduler) {
    try {
      await BackgroundScheduler().register();
    } catch (_) {
      // Plugin not available on this platform — silently skip.
    }
  }
  runApp(const ProviderScope(child: MigraineWeatherrApp()));
}
