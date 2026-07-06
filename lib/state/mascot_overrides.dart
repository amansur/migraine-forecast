import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A today-only manual mascot pick: tap-to-cycle state on the Today screen.
/// Applies only while [dateKey] is today's local date and [band] matches the
/// band being rendered; stale state is inert (treated as offset 0).
typedef MascotCycle = ({String dateKey, RiskBand band, int offset});

/// Local-date key used to expire the cycle at midnight.
String mascotDateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// In-memory only: resets on app restart. Null = daily seeded pick.
final mascotCycleProvider = StateProvider<MascotCycle?>((_) => null);

/// Debug-only presentation override for the displayed risk band.
/// Null = auto (real assessment). Never persisted; set from the Settings
/// Developer section, which is compiled out of release builds.
final debugBandOverrideProvider = StateProvider<RiskBand?>((_) => null);
