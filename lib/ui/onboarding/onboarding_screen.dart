import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../state/backfill_provider.dart';
import '../../state/onboarding_provider.dart';
import '../../state/providers.dart';
import '../../state/risk_assessment_provider.dart';
import '../../state/trigger_flags_provider.dart';
import '../shared/mascot/mascot_widget.dart';

/// User-facing labels for the multi-select. Each maps to one or more module IDs;
/// a single chip can stand in for a family of related modules.
const _triggerOptions = <String, List<String>>{
  'Stress': ['stress'],
  'Sleep': ['sleep_deficit'],
  'Weather': ['pressure_drop', 'humidity', 'temp_swing'],
  'Air quality': ['air_quality'],
  'Hormones': ['menstrual_phase'],
  'Alcohol': ['alcohol'],
  'Caffeine': ['caffeine'],
  'Dehydration': ['hydration'],
};

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final Set<String> _selected = {};
  bool _isLoading = false;
  final _mascot = MascotController();

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Migraine Forecast')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Which of these have triggered migraines for you?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You can change these any time in Settings.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Center(
                child: MascotWidget(band: RiskBand.low, size: 80, controller: _mascot),
              ),
              if (kIsWeb)
                Semantics(
                  link: true,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => unawaited(launchUrl(Uri(path: '/home/'))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Learn how it works →',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _triggerOptions.keys.map((label) {
                      final selected = _selected.contains(label);
                      return FilterChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          v ? _selected.add(label) : _selected.remove(label);
                        }),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _Disclaimer(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _finish,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Text('Finish'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Capture values from BuildContext before any async gap.
    final container = ProviderScope.containerOf(context, listen: false);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    try {
      await ref.read(permissionServiceProvider).requestLocation();
    } on Exception catch (e) {
      // Permission/Geolocator failures are non-fatal — onboarding still completes
      // and the Today lifecycle hook handles re-fetching once a fix is available.
      debugPrint('Location request failed: $e');
    }

    try {
      final saveFlags = ref.read(saveTriggerFlagsProvider);
      final moduleIds = <String>{
        for (final label in _selected) ...?_triggerOptions[label],
      };
      await saveFlags(UserTriggerFlags(flaggedModuleIds: moduleIds));
      final markDone = ref.read(markOnboardingCompletedProvider);
      await markDone();

      // Cheerful wave before we navigate away.
      _mascot.wave();
      if (!disableAnimations) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }

      // Wait for the provider to resolve before navigating, otherwise the router redirect will bounce us back
      await ref.read(onboardingCompletedProvider.future);
      
      // Invalidate the risk assessment provider so that it re-runs with the new location permission.
      ref.invalidate(riskAssessmentProvider);
      ref.invalidate(tomorrowRiskAssessmentProvider);

      // Fire-and-forget: populate historical assessments in the background.
      // Use the long-lived ProviderContainer rather than the widget's ref, so
      // the run survives the imminent navigation away from this screen.
      unawaited(launchBackfill(container));

      if (mounted) context.go('/today');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();
  @override
  Widget build(BuildContext context) {
    return Text(
      'Migraine Forecast is decision-support, not medical advice. Please consult a clinician for diagnosis or treatment.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
    );
  }
}
