import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/state/settings_provider.dart';
import 'package:migraine_weatherr/ui/settings/settings_screen.dart';

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags(flaggedModuleIds: {'stress'});
  @override Future<UserTriggerFlags> load() async => _f;
  @override Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  testWidgets('renders trigger list and reflects flagged state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
          riskDisplayModeProvider.overrideWith((ref) async => RiskDisplayMode.gauge),
          notificationsEnabledProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const SettingsScreen()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stress'), findsOneWidget);
    expect(find.text('Pressure changes'), findsOneWidget);
  });
}
