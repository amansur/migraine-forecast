import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/sources/location_source.dart';
import '../common/location_search_dialog.dart';
import '../../state/cycle_provider.dart';
import '../../state/onboarding_provider.dart';
import '../../state/backfill_provider.dart';
import '../../state/providers.dart';
import '../../state/risk_assessment_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/trigger_flags_provider.dart';
import '../cycle/baseline_severity_dialog.dart';
import '../shared/unit_formatter.dart';
import 'oura_settings_card.dart';

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
          ref.watch(comfortModeProvider).when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (mode) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Comfort Mode'),
                  const SizedBox(height: 4),
                  Text(
                    _comfortSubtitle(mode),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ComfortMode>(
                    key: const Key('comfort-mode-selector'),
                    segments: const [
                      ButtonSegment(value: ComfortMode.off, label: Text('Off')),
                      ButtonSegment(value: ComfortMode.auto, label: Text('Auto')),
                      ButtonSegment(value: ComfortMode.always, label: Text('Always')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => ref.read(setComfortModeProvider)(s.first),
                  ),
                ],
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
            data: (loc) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text('Location'),
                  subtitle: loc != null
                      ? Text('${loc.lat.toStringAsFixed(4)}, ${loc.lon.toStringAsFixed(4)}')
                      : const Text('Auto (GPS)'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _showLocationDialog(context, ref, loc),
                ),
                if (loc != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: TextButton.icon(
                      icon: const Icon(Icons.my_location),
                      label: const Text('Reset to auto location'),
                      onPressed: () => ref.read(clearManualLocationProvider)(),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Text('Cycle', style: Theme.of(context).textTheme.titleSmall),
          const _CycleSettingsSection(),
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
          const Divider(),
          Text('Manage Data', style: Theme.of(context).textTheme.titleSmall),
          ListTile(
            title: const Text('Export JSON Data'),
            subtitle: const Text('Copy or save your attacks, journal entries, and settings.'),
            trailing: const Icon(Icons.download_outlined),
            onTap: () => _showExportDialog(context, ref),
          ),
          Consumer(builder: (context, ref, _) {
            final running = ref.watch(backfillProgressProvider) != null;
            return ListTile(
              title: const Text('Rebuild risk history'),
              subtitle: Text(running
                  ? 'In progress — open Insights to see progress.'
                  : 'Refetch weather and recompute risk for the last 90 days.'),
              trailing: const Icon(Icons.refresh),
              enabled: !running,
              onTap: running
                  ? null
                  : () {
                      final container = ProviderScope.containerOf(context, listen: false);
                      launchBackfill(container, forceRebuild: true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Rebuilding risk history — see Insights for progress.'),
                      ));
                    },
            );
          }),
          const Divider(),
          Text('Danger Zone', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.error)),
          ListTile(
            title: Text('Clear all data', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            subtitle: const Text('Permanently delete all logs, settings, and risk history. Resets the app to the onboarding state.'),
            trailing: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear all data?'),
                  content: const Text('This will permanently delete all your logs, settings, and risk history. This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete Everything'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(databaseProvider).clearAllData();
                ref.invalidate(onboardingCompletedProvider);
                ref.invalidate(riskAssessmentProvider);
                ref.invalidate(tomorrowRiskAssessmentProvider);
                // Wait for the new false value to resolve before navigating
                await ref.read(onboardingCompletedProvider.future);
                if (context.mounted) {
                  context.go('/onboarding');
                }
              }
            },
          ),
          const Divider(),
          const OuraSettingsCard(),
        ],
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ExportDataDialog(ref: ref),
    );
  }

  Future<void> _showLocationDialog(BuildContext context, WidgetRef ref, UserLocation? current) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => LocationSearchDialog(
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

  String _comfortSubtitle(ComfortMode m) {
    switch (m) {
      case ComfortMode.off: return 'Standard theme always. Log Attack screen still uses Comfort.';
      case ComfortMode.auto: return 'Warm low-contrast theme automatically while an attack is in progress.';
      case ComfortMode.always: return 'Warm low-contrast theme at all times.';
    }
  }

  String _overrideLabel(double v) {
    final s = v >= 0 ? '+${v.toInt()}' : '${v.toInt()}';
    return v == 0 ? '0' : s;
  }
}

// LocationSearchDialog extracted to lib/ui/common/location_search_dialog.dart

class _CycleSettingsSection extends ConsumerWidget {
  const _CycleSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync = ref.watch(cycleTrackingEnabledProvider);
    final enabled = enabledAsync.asData?.value ?? true;
    final periodsAsync = ref.watch(recentPeriodsProvider);
    final current = ref.watch(currentPeriodProvider);
    final inProgress = current != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: const Key('cycle-tracking-toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Cycle tracking'),
          subtitle: const Text('Show period logging, phase ribbon, and cycle row. Existing data is kept when off.'),
          value: enabled,
          onChanged: (v) => ref.read(setCycleTrackingEnabledProvider)(v),
        ),
        if (!enabled) const SizedBox.shrink() else ...[
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: OutlinedButton.icon(
            key: const Key('settings-period-button'),
            icon: Icon(inProgress ? Icons.water_drop : Icons.water_drop_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(inProgress ? 'End period' : 'Log period'),
            ),
            onPressed: () async {
              final journal = ref.read(journalSourceProvider);
              if (inProgress) {
                await journal.endPeriod(current.startedAt, DateTime.now().toUtc());
                return;
              }
              final v = await BaselineSeverityDialog.show(context);
              if (v == null) return;
              await journal.addPeriod(PeriodEvent(
                startedAt: DateTime.now().toUtc(),
                baselineSeverity: v,
              ));
            },
          ),
        ),
        periodsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (periods) {
            if (periods.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No periods logged yet.'),
              );
            }
            final fmt = DateFormat('MMM d, y');
            return Column(
              children: periods.map((p) {
                final start = fmt.format(p.startedAt.toLocal());
                final endLabel = p.endedAt == null
                    ? 'in progress'
                    : '– ${fmt.format(p.endedAt!.toLocal())}';
                return ListTile(
                  key: Key('period-row-${p.startedAt.toIso8601String()}'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.water_drop, color: Color(0xFFC15B7A)),
                  title: Text('$start $endLabel'),
                  subtitle: Text('Severity ${p.baselineSeverity}'),
                  trailing: IconButton(
                    key: Key('period-delete-${p.startedAt.toIso8601String()}'),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove this period?'),
                          content: const Text('The period record and any per-day severity overrides inside it will be deleted.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref.read(journalSourceProvider).deletePeriod(p.startedAt);
                      }
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
        ],
      ],
    );
  }
}

class _ExportDataDialog extends StatefulWidget {
  final WidgetRef ref;
  const _ExportDataDialog({required this.ref});

  @override
  State<_ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<_ExportDataDialog> {
  bool _loading = false;

  Future<void> _copyToClipboard() async {
    setState(() => _loading = true);
    try {
      final json = await widget.ref.read(exportRepoProvider).buildJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveToDocuments() async {
    setState(() => _loading = true);
    try {
      final json = await widget.ref.read(exportRepoProvider).buildJson();
      final dir = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final path = '${dir.path}/migraine_forecast_export_$dateStr.json';
      await File(path).writeAsString(json);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(content: Text('Saved to $path')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export JSON Data'),
      content: const Text('Choose how to export your data. Derived data (risk assessments, weather snapshots) is excluded.'),
      actions: _loading
          ? [const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())]
          : [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(onPressed: _copyToClipboard, child: const Text('Copy to Clipboard')),
              TextButton(onPressed: _saveToDocuments, child: const Text('Save to Documents')),
            ],
    );
  }
}
