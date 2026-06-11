import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/sources/location_source.dart';
import '../../data/sources/open_meteo/open_meteo_geocoder.dart';
import '../../state/providers.dart';
import '../../state/settings_provider.dart';
import '../../state/trigger_flags_provider.dart';
import '../shared/unit_formatter.dart';

const _moduleLabels = <String, String>{
  'pressure_drop': 'Pressure changes',
  'humidity': 'Humidity',
  'temp_swing': 'Temp swing',
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
          const SizedBox(height: 8),
          ref.watch(temperatureUnitProvider).when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (unit) => ListTile(
              title: const Text('Temperature'),
              trailing: SegmentedButton<TemperatureUnit>(
                segments: const [
                  ButtonSegment(value: TemperatureUnit.celsius, label: Text('°C')),
                  ButtonSegment(value: TemperatureUnit.fahrenheit, label: Text('°F')),
                ],
                selected: {unit},
                onSelectionChanged: (s) => ref.read(setTemperatureUnitProvider)(s.first),
              ),
            ),
          ),
          ref.watch(pressureUnitProvider).when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (unit) => ListTile(
              title: const Text('Pressure'),
              trailing: SegmentedButton<PressureUnit>(
                segments: const [
                  ButtonSegment(value: PressureUnit.hpa, label: Text('hPa')),
                  ButtonSegment(value: PressureUnit.mmhg, label: Text('mmHg')),
                ],
                selected: {unit},
                onSelectionChanged: (s) => ref.read(setPressureUnitProvider)(s.first),
              ),
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
          Text('Location', style: Theme.of(context).textTheme.titleSmall),
          ref.watch(manualLocationProvider).when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (loc) => ListTile(
              title: const Text('Manual location'),
              subtitle: loc != null
                  ? Text('${loc.lat.toStringAsFixed(4)}, ${loc.lon.toStringAsFixed(4)}')
                  : const Text('Not set — using GPS'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loc != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear manual location',
                      onPressed: () => ref.read(clearManualLocationProvider)(),
                    ),
                  const Icon(Icons.edit_outlined),
                ],
              ),
              onTap: () => _showLocationDialog(context, ref, loc),
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

  Future<void> _showLocationDialog(BuildContext context, WidgetRef ref, UserLocation? current) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _LocationSearchDialog(
        geocoder: ref.read(geocoderProvider),
        onPick: (result) => ref.read(setManualLocationProvider)(result.lat, result.lon),
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

class _LocationSearchDialog extends StatefulWidget {
  final OpenMeteoGeocoder geocoder;
  final void Function(GeocodingResult) onPick;
  const _LocationSearchDialog({required this.geocoder, required this.onPick});

  @override
  State<_LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<_LocationSearchDialog> {
  final _ctrl = TextEditingController();
  List<GeocodingResult> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final results = await widget.geocoder.search(q);
      setState(() { _results = results; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Search failed: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set location'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      labelText: 'City, state, country or postal code',
                      hintText: 'San Francisco, CA',
                    ),
                    onSubmitted: (_) => _search(),
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ],
            ),
            if (_loading) const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    return ListTile(
                      title: Text(r.displayName),
                      subtitle: Text('${r.lat.toStringAsFixed(4)}, ${r.lon.toStringAsFixed(4)}'),
                      onTap: () {
                        widget.onPick(r);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ] else if (!_loading && _ctrl.text.isNotEmpty && _results.isEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('No results — try a different search term'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}
