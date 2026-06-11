import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/background_scheduler.dart';
import 'services/notification_service.dart';

bool get _supportsLocalNotifications =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid || Platform.isMacOS);

bool get _supportsBackgroundScheduler =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
