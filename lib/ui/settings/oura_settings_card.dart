import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/settings_provider.dart';

// TODO: These providers will be created in Task 12 (Oura Auth Providers)
// final ouraAuthStateProvider = FutureProvider<bool>((ref) async {
//   return ref.watch(ouraAuthManagerProvider).isAuthenticated;
// });
//
// final ouraUserEmailProvider = FutureProvider<String?>((ref) async {
//   return ref.watch(ouraAuthManagerProvider).userEmail;
// });

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
    // TODO: Replace with actual providers when available in Task 12
    // final authStateAsync = ref.watch(ouraAuthStateProvider);
    // final userEmailAsync = ref.watch(ouraUserEmailProvider);
    final preference = ref.watch(healthSourcePreferenceProvider);

    // Placeholder values for now - will use actual providers after Task 12
    const isAuthenticated = false;

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
                isAuthenticated ? 'Connected' : 'Not connected',
                style: TextStyle(
                  color: isAuthenticated
                      ? Colors.green
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              trailing: OutlinedButton(
                onPressed: () {
                  // TODO: Implement OAuth flow in Task 12
                  // If authenticated: call logout action
                  // If not authenticated: call login action
                  if (isAuthenticated) {
                    // ref.read(ouraLogoutProvider)();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('[TODO] Disconnect Oura will be implemented in Task 12'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('[TODO] Connect Oura will be implemented in Task 12'),
                      ),
                    );
                  }
                },
                child: Text(isAuthenticated ? 'Disconnect' : 'Connect'),
              ),
            ),
            if (isAuthenticated) ...[
              const SizedBox(height: 16),
              Text(
                'Data Source Preference',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              RadioListTile<HealthSourcePreference>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Oura Ring'),
                value: HealthSourcePreference.oura,
                groupValue: preference,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(healthSourcePreferenceProvider.notifier).setPreference(value);
                  }
                },
              ),
              RadioListTile<HealthSourcePreference>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Apple Health'),
                value: HealthSourcePreference.appleHealth,
                groupValue: preference,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(healthSourcePreferenceProvider.notifier).setPreference(value);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
