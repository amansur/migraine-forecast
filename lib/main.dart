import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/background_scheduler.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notif = NotificationService();
  await notif.init();
  await BackgroundScheduler().register();
  runApp(const ProviderScope(child: MigraineWeatherrApp()));
}
