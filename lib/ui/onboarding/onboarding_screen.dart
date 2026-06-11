import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/onboarding_provider.dart';
import '../../state/providers.dart';
import '../../state/trigger_flags_provider.dart';

/// User-facing labels for the multi-select. Each maps to a module ID.
const _triggerOptions = <String, String>{
  'Stress': 'stress',
  'Sleep': 'sleep_deficit',
  'Weather': 'pressure_drop',
  'Hormones': 'menstrual_phase',
  'Alcohol': 'alcohol',
  'Caffeine': 'caffeine',
  'Dehydration': 'hydration',
};

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Migraine Weatherr')),
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
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _triggerOptions.entries.map((e) {
                      final selected = _selected.contains(e.value);
                      return FilterChip(
                        label: Text(e.key),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          v ? _selected.add(e.value) : _selected.remove(e.value);
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
                  onPressed: _finish,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Finish'),
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
    await ref.read(permissionServiceProvider).requestLocation();
    final saveFlags = ref.read(saveTriggerFlagsProvider);
    await saveFlags(UserTriggerFlags(flaggedModuleIds: Set.of(_selected)));
    final markDone = ref.read(markOnboardingCompletedProvider);
    await markDone();
    if (mounted) context.go('/today');
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();
  @override
  Widget build(BuildContext context) {
    return Text(
      'Migraine Weatherr is decision-support, not medical advice. Please consult a clinician for diagnosis or treatment.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
    );
  }
}
