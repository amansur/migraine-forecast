import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../state/outlook_provider.dart';

/// Five tappable chips for d+2..d+6, extending Today/Tomorrow into a week
/// view. Weather-driven modules carry the forecast; health modules sit out
/// with low confidence, which the engine already accounts for.
class OutlookStrip extends ConsumerWidget {
  const OutlookStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outlook = ref.watch(outlookProvider);
    return outlook.when(
      loading: () => const SizedBox(height: 72),
      error: (_, __) => const SizedBox.shrink(),
      data: (days) {
        if (days.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final a = days[i];
              final d = a.targetDate.toUtc();
              final color = colorForBand(a.band.name);
              return ActionChip(
                key: Key('outlook-${d.toIso8601String().substring(0, 10)}'),
                backgroundColor: color.withValues(alpha: 0.18),
                side: BorderSide(color: color),
                onPressed: () => context.push('/outlook-day', extra: a),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(DateFormat.E()
                        .format(DateTime(d.year, d.month, d.day))),
                    Text('${a.score}',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
