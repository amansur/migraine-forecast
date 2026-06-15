import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/oura_settings_provider.dart';
import '../../state/settings_provider.dart';

/// Settings card for Oura Ring health data integration.
///
/// Displays:
/// - Connection status (Connected / Not connected)
/// - Connect/Disconnect button
/// - Data source preference radio buttons (when authenticated)
class OuraSettingsCard extends ConsumerWidget {
  const OuraSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(ouraAuthStateProvider);
    final preference = ref.watch(healthSourcePreferenceProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Data Sources',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Connected Accounts',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Oura Ring'),
              subtitle: Text(
                auth.authenticated ? (auth.email ?? 'Connected') : 'Not connected',
                style: TextStyle(
                  color: auth.authenticated
                      ? Colors.green
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              trailing: OutlinedButton(
                onPressed: () async {
                  if (auth.authenticated) {
                    await ref.read(ouraAuthStateProvider.notifier).logout();
                  } else {
                    try {
                      await ref.read(ouraOAuthFlowProvider).connect();
                      await ref
                          .read(ouraAuthStateProvider.notifier)
                          .refreshFromManager();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  }
                },
                child: Text(auth.authenticated ? 'Disconnect' : 'Connect'),
              ),
            ),
            if (auth.authenticated) ...[
              const SizedBox(height: 16),
              Text(
                'Data Source Preference',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              RadioGroup<HealthSourcePreference>(
                groupValue: preference,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(healthSourcePreferenceProvider.notifier)
                        .setPreference(value);
                  }
                },
                child: Column(
                  children: const [
                    RadioListTile<HealthSourcePreference>(
                      value: HealthSourcePreference.oura,
                      title: Text('Oura Ring'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<HealthSourcePreference>(
                      value: HealthSourcePreference.appleHealth,
                      title: Text('Apple Health'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
