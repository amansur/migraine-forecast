import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../state/settings_provider.dart';

class HealthMetricsCard extends ConsumerWidget {
  const HealthMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(healthMetricsProvider);
    final isRefreshing = ref.watch(healthMetricsRefreshingProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and refresh button/spinner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Health Metrics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (isRefreshing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _refreshMetrics(ref),
                    constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Metrics display
            metricsAsync.when(
              data: (metrics) => _buildMetricsContent(context, metrics),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Text(
                'Error loading metrics: $error',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsContent(BuildContext context, HealthMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sleep Score
        _MetricRow(
          label: 'Sleep Score',
          value: metrics.sleepScore?.toString() ?? '--',
        ),
        const SizedBox(height: 12),
        // Lowest Heart Rate
        _MetricRow(
          label: 'Lowest HR',
          value: metrics.lowestHeartRate != null
              ? '${metrics.lowestHeartRate} bpm'
              : '--',
        ),
        const SizedBox(height: 12),
        // Activity Score
        _MetricRow(
          label: 'Activity Score',
          value: metrics.activityScore?.toString() ?? '--',
        ),
        const SizedBox(height: 16),
        // Data source and last fetch time
        Text(
          'Updated ${_timeAgo(metrics.lastFetched)} from ${_sourceLabel(metrics.source)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) {
      return 'never';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _sourceLabel(DataSource source) {
    switch (source) {
      case DataSource.oura:
        return 'Oura Ring';
      case DataSource.appleHealth:
        return 'Apple Health';
      case DataSource.healthConnect:
        return 'Health Connect';
      case DataSource.manual:
        return 'Manual Entry';
    }
  }

  Future<void> _refreshMetrics(WidgetRef ref) async {
    ref.read(healthMetricsRefreshingProvider.notifier).state = true;
    try {
      // ignore: unused_result
      ref.refresh(healthMetricsProvider);
    } finally {
      ref.read(healthMetricsRefreshingProvider.notifier).state = false;
    }
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
