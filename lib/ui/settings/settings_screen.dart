import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/settings_provider.dart';
import '../../state/trigger_flags_provider.dart';

const _moduleLabels = <String, String>{
  'pressure_drop': 'Pressure changes',
  'humidity_temp_swing': 'Humidity + temp swing',
  'air_quality': 'Air quality',
  'sleep_deficit': 'Sleep',
  'hrv_letdown': 'HRV / stress let-down',
  'menstrual_phase': 'Menstrual cycle',
  'alcohol': 'Alcohol',
  'caffeine': 'Caffeine',
  'stress': 'Stress',
  'hydration': 'Hydration',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(triggerFlagsProvider);
    final modeAsync = ref.watch(riskDisplayModeProvider);
    final notifAsync = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Display', style: Theme.of(context).textTheme.titleSmall),
          modeAsync.when(
            loading: () => const ListTile(
              title: Text('Risk display'),
              trailing: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => ListTile(title: const Text('Risk display'), subtitle: Text('Error: $e')),
            data: (mode) => ListTile(
              title: const Text('Risk display'),
              subtitle: Text(_modeLabel(mode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final pick = await showModalBottomSheet<RiskDisplayMode>(
                  context: context,
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: RiskDisplayMode.values.map((m) => ListTile(
                          title: Text(_modeLabel(m)),
                          selected: m == mode,
                          onTap: () => Navigator.pop(ctx, m),
                        )).toList(),
                  ),
                );
                if (pick != null) await ref.read(setRiskDisplayModeProvider)(pick);
              },
            ),
          ),
          const Divider(),
          Text('Notifications', style: Theme.of(context).textTheme.titleSmall),
          notifAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (enabled) => SwitchListTile(
              title: const Text('High-risk alerts'),
              subtitle: const Text('Background notifications come in Plan 4'),
              value: enabled,
              onChanged: (v) => ref.read(setNotificationsEnabledProvider)(v),
            ),
          ),
          const Divider(),
          Text('Triggers', style: Theme.of(context).textTheme.titleSmall),
          flagsAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Text('Error: $e'),
            data: (flags) {
              return Column(
                children: _moduleLabels.entries.map((e) {
                  final flagged = flags.flaggedModuleIds.contains(e.key);
                  final override = flags.weightOverrides[e.key] ?? 0;
                  return ExpansionTile(
                    title: Text(e.value),
                    subtitle: Text(flagged ? 'Tracking — weight ${_overrideLabel(override)}' : 'Not flagged'),
                    children: [
                      SwitchListTile(
                        title: const Text('I think this triggers me'),
                        value: flagged,
                        onChanged: (v) async {
                          final next = Set<String>.from(flags.flaggedModuleIds);
                          v ? next.add(e.key) : next.remove(e.key);
                          await ref.read(saveTriggerFlagsProvider)(UserTriggerFlags(
                            flaggedModuleIds: next,
                            weightOverrides: flags.weightOverrides,
                          ));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text('Weight'),
                            Expanded(
                              child: Slider(
                                value: override,
                                min: -2,
                                max: 2,
                                divisions: 4,
                                label: _overrideLabel(override),
                                onChanged: (v) async {
                                  final overrides = Map<String, double>.from(flags.weightOverrides);
                                  if (v == 0) {
                                    overrides.remove(e.key);
                                  } else {
                                    overrides[e.key] = v;
                                  }
                                  await ref.read(saveTriggerFlagsProvider)(UserTriggerFlags(
                                    flaggedModuleIds: flags.flaggedModuleIds,
                                    weightOverrides: overrides,
                                  ));
                                },
                              ),
                            ),
                            Text(_overrideLabel(override)),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _modeLabel(RiskDisplayMode m) {
    switch (m) {
      case RiskDisplayMode.gauge: return 'Gauge';
      case RiskDisplayMode.numeric: return 'Number';
      case RiskDisplayMode.weatherIcon: return 'Weather icon';
    }
  }

  String _overrideLabel(double v) {
    final s = v >= 0 ? '+${v.toInt()}' : '${v.toInt()}';
    return v == 0 ? '0' : s;
  }
}
