import 'dart:io';
import 'dart:typed_data';

import 'package:domain/domain.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repos/import_repo.dart';
import '../../data/sources/location_source.dart';
import '../common/location_search_dialog.dart';
import '../../state/cycle_provider.dart';
import '../../state/mascot_overrides.dart';
import '../../state/onboarding_provider.dart';
import '../../state/backfill_provider.dart';
import '../../state/providers.dart';
import '../../state/risk_assessment_provider.dart';
import '../../state/settings_provider.dart';
import '../../state/trigger_flags_provider.dart';
import '../cycle/baseline_severity_dialog.dart';
import '../shared/animations/celebration_overlay.dart';
import '../shared/mascot/mascot_widget.dart';
import '../shared/unit_formatter.dart';
import 'oura_settings_card.dart';
import '../shared/module_labels.dart';
import '../../state/medication_provider.dart';
import '../../state/outlook_provider.dart';

// User-flaggable triggers: excludes 'refractory' (internal post-attack
// damping, not a lifestyle trigger) and 'intraday_pressure_swing' (flagged
// together with pressure_drop).
final _moduleLabels = <String, String>{...moduleLabels}
  ..remove('refractory')
  ..remove('intraday_pressure_swing');

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _mascot = MascotController();

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }

  void _celebrateSave() {
    if (!mounted) return;
    CelebrationOverlay.showCheckmark(context, controller: _mascot);
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final flagsAsync = ref.watch(triggerFlagsProvider);
    final modeAsync = ref.watch(riskDisplayModeProvider);
    final notifAsync = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MascotWidget(
                band: RiskBand.low,
                size: 80,
                controller: _mascot,
              ),
            ),
          ),
          Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
          const Divider(),
          Text('Display', style: Theme.of(context).textTheme.titleSmall),
          modeAsync.when(
            loading: () => const ListTile(
              title: Text('Risk display'),
              trailing: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => ListTile(
              title: const Text('Risk display'),
              subtitle: Text('Error: $e'),
            ),
            data: (mode) => ListTile(
              title: const Text('Risk display'),
              subtitle: Text(_modeLabel(mode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final pick = await showModalBottomSheet<RiskDisplayMode>(
                  context: context,
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: RiskDisplayMode.values
                        .map(
                          (m) => ListTile(
                            title: Text(_modeLabel(m)),
                            selected: m == mode,
                            onTap: () => Navigator.pop(ctx, m),
                          ),
                        )
                        .toList(),
                  ),
                );
                if (pick != null) {
                  await ref.read(setRiskDisplayModeProvider)(pick);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          ref
              .watch(temperatureUnitProvider)
              .when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Error: $e'),
                data: (unit) => ListTile(
                  title: const Text('Temperature'),
                  trailing: SegmentedButton<TemperatureUnit>(
                    segments: const [
                      ButtonSegment(
                        value: TemperatureUnit.celsius,
                        label: Text('°C'),
                      ),
                      ButtonSegment(
                        value: TemperatureUnit.fahrenheit,
                        label: Text('°F'),
                      ),
                    ],
                    selected: {unit},
                    onSelectionChanged: (s) =>
                        ref.read(setTemperatureUnitProvider)(s.first),
                  ),
                ),
              ),
          ref
              .watch(pressureUnitProvider)
              .when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Error: $e'),
                data: (unit) => ListTile(
                  title: const Text('Pressure'),
                  trailing: SegmentedButton<PressureUnit>(
                    segments: const [
                      ButtonSegment(
                        value: PressureUnit.hpa,
                        label: Text('hPa'),
                      ),
                      ButtonSegment(
                        value: PressureUnit.mmhg,
                        label: Text('mmHg'),
                      ),
                    ],
                    selected: {unit},
                    onSelectionChanged: (s) =>
                        ref.read(setPressureUnitProvider)(s.first),
                  ),
                ),
              ),
          ref
              .watch(comfortModeProvider)
              .when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Error: $e'),
                data: (mode) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                          ButtonSegment(
                            value: ComfortMode.off,
                            label: Text('Off'),
                          ),
                          ButtonSegment(
                            value: ComfortMode.auto,
                            label: Text('Auto'),
                          ),
                          ButtonSegment(
                            value: ComfortMode.always,
                            label: Text('Always'),
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (s) =>
                            ref.read(setComfortModeProvider)(s.first),
                      ),
                    ],
                  ),
                ),
              ),
          ref
              .watch(darkPaletteProvider)
              .when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Error: $e'),
                data: (selected) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dark palette'),
                      const SizedBox(height: 4),
                      Text(
                        'Colors used when comfort mode is on',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final choice in DarkPaletteChoice.values)
                            _PaletteCard(
                              choice: choice,
                              selected: choice == selected,
                              onTap: () =>
                                  ref.read(setDarkPaletteProvider)(choice),
                            ),
                        ],
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
          ref
              .watch(manualLocationProvider)
              .when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('Error: $e'),
                data: (loc) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: const Text('Location'),
                      subtitle: loc != null
                          ? Text(
                              '${loc.lat.toStringAsFixed(4)}, ${loc.lon.toStringAsFixed(4)}',
                            )
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
                          onPressed: () =>
                              ref.read(clearManualLocationProvider)(),
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
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (flags) {
              return Column(
                children: _moduleLabels.entries.map((e) {
                  final flagged = flags.flaggedModuleIds.contains(e.key);
                  final override = flags.weightOverrides[e.key] ?? 0;
                  return ExpansionTile(
                    title: Text(e.value),
                    subtitle: Text(
                      flagged
                          ? 'Tracking — weight ${_overrideLabel(override)}'
                          : 'Not flagged',
                    ),
                    children: [
                      SwitchListTile(
                        title: const Text('I think this triggers me'),
                        value: flagged,
                        onChanged: (v) async {
                          final next = Set<String>.from(flags.flaggedModuleIds);
                          v ? next.add(e.key) : next.remove(e.key);
                          await ref.read(saveTriggerFlagsProvider)(
                            UserTriggerFlags(
                              flaggedModuleIds: next,
                              weightOverrides: flags.weightOverrides,
                            ),
                          );
                          _celebrateSave();
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
                                  final overrides = Map<String, double>.from(
                                    flags.weightOverrides,
                                  );
                                  if (v == 0) {
                                    overrides.remove(e.key);
                                  } else {
                                    overrides[e.key] = v;
                                  }
                                  await ref.read(saveTriggerFlagsProvider)(
                                    UserTriggerFlags(
                                      flaggedModuleIds: flags.flaggedModuleIds,
                                      weightOverrides: overrides,
                                    ),
                                  );
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
            title: const Text('Export Data'),
            subtitle: const Text(
              'Share your attacks, journal entries, risk history, and settings as JSON or CSV.',
            ),
            trailing: const Icon(Icons.download_outlined),
            onTap: () => _showExportDialog(context, ref),
          ),
          ListTile(
            title: const Text('Import Data'),
            subtitle: const Text('Restore from a previous JSON or CSV export.'),
            trailing: const Icon(Icons.upload_outlined),
            onTap: () => _importData(context, ref),
          ),
          Consumer(
            builder: (context, ref, _) {
              final running = ref.watch(backfillProgressProvider) != null;
              return ListTile(
                title: const Text('Rebuild risk history'),
                subtitle: Text(
                  running
                      ? 'In progress — open Insights to see progress.'
                      : 'Refetch weather and recompute risk for the last 90 days.',
                ),
                trailing: const Icon(Icons.refresh),
                enabled: !running,
                onTap: running
                    ? null
                    : () {
                        final container = ProviderScope.containerOf(
                          context,
                          listen: false,
                        );
                        launchBackfill(container, forceRebuild: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Rebuilding risk history — see Insights for progress.',
                            ),
                          ),
                        );
                      },
              );
            },
          ),
          const Divider(),
          Text(
            'Danger Zone',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          ListTile(
            title: Text(
              'Clear all data',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text(
              'Permanently delete all logs, settings, and risk history. Resets the app to the onboarding state.',
            ),
            trailing: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear all data?'),
                  content: const Text(
                    'This will permanently delete all your logs, settings, and risk history. This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(ctx).colorScheme.error,
                      ),
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
                ref.invalidate(outlookProvider);
                ref.invalidate(recentMedicationDosesProvider);
                ref.invalidate(mohStatusProvider);
                ref.invalidate(medicationNamesProvider);
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
          const Divider(),
          Text('Developer', style: Theme.of(context).textTheme.titleSmall),
          ListTile(
            key: const Key('debug-band-override-row'),
            title: const Text('Risk band override'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Auto'),
                    selected: ref.watch(debugBandOverrideProvider) == null,
                    onSelected: (_) =>
                        ref.read(debugBandOverrideProvider.notifier).state =
                            null,
                  ),
                  for (final b in RiskBand.values)
                    ChoiceChip(
                      label: Text(_bandLabel(b)),
                      selected: ref.watch(debugBandOverrideProvider) == b,
                      onSelected: (_) =>
                          ref.read(debugBandOverrideProvider.notifier).state =
                              b,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _bandLabel(RiskBand b) => switch (b) {
    RiskBand.low => 'Low',
    RiskBand.moderate => 'Moderate',
    RiskBand.high => 'High',
    RiskBand.veryHigh => 'Very High',
  };

  Future<void> _showExportDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _ExportDataDialog(ref: ref),
    );
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    // 1. Pick a file. FileType.any because MIME/UTI extension filtering is
    //    unreliable on Android/iOS; we validate the extension below.
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return; // user cancelled

    final path = result.files.first.path;
    if (path == null) return;

    final ext = path.toLowerCase().split('.').last;
    if (ext != 'json' && ext != 'zip') {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsupported File'),
          content: const Text(
            'Please select a .json or .zip file exported from Migraine Forecast.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Ask how to handle conflicts.
    if (!context.mounted) return;
    final mode = await showDialog<ImportMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How should we handle conflicts?'),
        content: const Text(
          'Replace all: wipe existing data for the imported tables and restore '
          'from file.\n\n'
          'Merge: keep existing records; only import records not already present.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImportMode.replaceAll),
            child: const Text('Replace All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImportMode.merge),
            child: const Text('Merge'),
          ),
        ],
      ),
    );
    if (mode == null) return; // user cancelled conflict dialog

    // 3. Import and report.
    try {
      final importRepo = ref.read(importRepoProvider);
      final int count;
      if (ext == 'json') {
        final jsonStr = await File(path).readAsString();
        count = await importRepo.importJson(jsonStr, mode);
      } else {
        final zipBytes = await File(path).readAsBytes();
        count = await importRepo.importCsvZip(zipBytes, mode);
      }
      if (context.mounted) {
        ref.invalidate(riskAssessmentProvider);
        ref.invalidate(tomorrowRiskAssessmentProvider);
        ref.invalidate(outlookProvider);
                ref.invalidate(recentMedicationDosesProvider);
                ref.invalidate(mohStatusProvider);
                ref.invalidate(medicationNamesProvider);
        ref.invalidate(riskDisplayModeProvider);
        ref.invalidate(notificationsEnabledProvider);
        ref.invalidate(cycleTrackingEnabledProvider);
        ref.invalidate(temperatureUnitProvider);
        ref.invalidate(pressureUnitProvider);
        ref.invalidate(comfortModeProvider);
        ref.invalidate(unitFormatterProvider);
        ref.invalidate(manualLocationProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Imported $count records')));
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Failed'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Failed'),
            content: Text(
              'An unexpected error occurred. Please try again.\n\n$e',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showLocationDialog(
    BuildContext context,
    WidgetRef ref,
    UserLocation? current,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => LocationSearchDialog(
        geocoder: ref.read(geocoderProvider),
        onPick: (result) =>
            ref.read(setManualLocationProvider)(result.lat, result.lon),
      ),
    );
  }

  String _modeLabel(RiskDisplayMode m) {
    switch (m) {
      case RiskDisplayMode.gauge:
        return 'Gauge';
      case RiskDisplayMode.numeric:
        return 'Number';
      case RiskDisplayMode.weatherIcon:
        return 'Weather icon';
    }
  }

  String _comfortSubtitle(ComfortMode m) {
    switch (m) {
      case ComfortMode.off:
        return 'Standard theme always. Log Attack screen still uses Comfort.';
      case ComfortMode.auto:
        return 'Warm low-contrast theme automatically while an attack is in progress.';
      case ComfortMode.always:
        return 'Warm low-contrast theme at all times.';
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
          subtitle: const Text(
            'Show period logging, phase ribbon, and cycle row. Existing data is kept when off.',
          ),
          value: enabled,
          onChanged: (v) => ref.read(setCycleTrackingEnabledProvider)(v),
        ),
        if (!enabled)
          const SizedBox.shrink()
        else ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: OutlinedButton.icon(
              key: const Key('settings-period-button'),
              icon: Icon(
                inProgress ? Icons.water_drop : Icons.water_drop_outlined,
              ),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(inProgress ? 'End period' : 'Log period'),
              ),
              onPressed: () async {
                final journal = ref.read(journalSourceProvider);
                if (inProgress) {
                  await journal.endPeriod(
                    current.startedAt,
                    DateTime.now().toUtc(),
                  );
                  return;
                }
                final v = await BaselineSeverityDialog.show(context);
                if (v == null) return;
                await journal.addPeriod(
                  PeriodEvent(
                    startedAt: DateTime.now().toUtc(),
                    baselineSeverity: v,
                  ),
                );
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
                    leading: const Icon(
                      Icons.water_drop,
                      color: Color(0xFFC15B7A),
                    ),
                    title: Text('$start $endLabel'),
                    subtitle: Text('Severity ${p.baselineSeverity}'),
                    trailing: IconButton(
                      key: Key(
                        'period-delete-${p.startedAt.toIso8601String()}',
                      ),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remove this period?'),
                            content: const Text(
                              'The period record and any per-day severity overrides inside it will be deleted.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(journalSourceProvider)
                              .deletePeriod(p.startedAt);
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

enum _ExportFormat { json, csv }

class _ExportDataDialog extends StatefulWidget {
  final WidgetRef ref;
  const _ExportDataDialog({required this.ref});

  @override
  State<_ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<_ExportDataDialog> {
  bool _loading = false;
  _ExportFormat _format = _ExportFormat.json;

  Future<void> _copyToClipboard() async {
    setState(() => _loading = true);
    try {
      final json = await widget.ref.read(exportRepoProvider).buildJsonFull();
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

  Future<void> _share() async {
    setState(() => _loading = true);
    try {
      final dir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final XFile xfile;

      if (_format == _ExportFormat.json) {
        final json = await widget.ref.read(exportRepoProvider).buildJsonFull();
        final path = '${dir.path}/migraine_forecast_export_$dateStr.json';
        await File(path).writeAsString(json);
        xfile = XFile(path, mimeType: 'application/json');
      } else {
        final Uint8List zipBytes = await widget.ref
            .read(exportRepoProvider)
            .buildCsvZipBytes();
        final path = '${dir.path}/migraine_forecast_export_$dateStr.zip';
        await File(path).writeAsBytes(zipBytes);
        xfile = XFile(path, mimeType: 'application/zip');
      }

      await Share.shareXFiles([xfile], subject: 'Migraine Forecast Export');
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Includes attacks, journal entries, risk history, and settings.',
          ),
          const SizedBox(height: 12),
          RadioGroup<_ExportFormat>(
            groupValue: _format,
            onChanged: (v) {
              if (_loading || v == null) return;
              setState(() => _format = v);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<_ExportFormat>(
                  title: const Text('JSON (full backup, importable)'),
                  value: _ExportFormat.json,
                  enabled: !_loading,
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<_ExportFormat>(
                  title: const Text('CSV (3-file ZIP, opens in spreadsheets)'),
                  value: _ExportFormat.csv,
                  enabled: !_loading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: _loading
          ? [
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _format == _ExportFormat.json
                    ? _copyToClipboard
                    : null,
                child: const Text('Copy to Clipboard'),
              ),
              FilledButton(onPressed: _share, child: const Text('Share')),
            ],
    );
  }
}

class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final DarkPaletteChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFor(choice);
    return InkWell(
      key: Key('palette-card-${choice.name}'),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? palette.primary : palette.onSurface.withAlpha(40),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _swatch(palette.surface),
                const SizedBox(width: 6),
                _swatch(palette.primary),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle, size: 18, color: palette.primary),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              palette.label,
              style: TextStyle(color: palette.onSurface, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
