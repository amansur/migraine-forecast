import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/state/mascot_overrides.dart';
import 'package:migraine_forecast/state/mascot_pool.dart';
import 'package:migraine_forecast/state/risk_assessment_provider.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';
import 'package:migraine_forecast/ui/today/today_screen.dart';

class _FakeNotifier extends RiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeNotifier(this.fixed);
  @override
  Future<RiskAssessment> build() async => fixed;
  @override
  Future<void> refresh() async => state = AsyncValue.data(fixed);
}

class _FakeTomorrowNotifier extends TomorrowRiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeTomorrowNotifier(this.fixed);
  @override
  Future<RiskAssessment> build() async => fixed;
  @override
  Future<void> refresh() async => state = AsyncValue.data(fixed);
}

RiskAssessment _ass(RiskBand band) => RiskAssessment(
      score: 58,
      band: band,
      contributors: const [],
      computedAt: DateTime.utc(2026, 6, 10, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

void main() {
  testWidgets('mascot appears above the risk display with current band', (tester) async {
    final today = _ass(RiskBand.high);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const Scaffold(body: Text('SETTINGS'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
        tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(RiskBand.moderate))),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    ));
    await tester.pump();

    expect(find.byType(MascotWidget), findsOneWidget);
    final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
    expect(mascot.band, RiskBand.high);

    // Tapping the mascot triggers a wiggle — no bottom sheet opens.
    await tester.tap(find.byKey(const Key('mascot-tap-target')));
    await tester.pumpAndSettle();
    expect(find.text('Choose your companion'), findsNothing);
  });

  testWidgets('tapping the mascot cycles to another pool member of the same band',
      (tester) async {
    final today = _ass(RiskBand.moderate);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
        tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(RiskBand.low))),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    ));
    await tester.pump();

    String asset() {
      final img = tester.widget<Image>(find.descendant(
          of: find.byType(MascotWidget), matching: find.byType(Image)));
      return (img.image as AssetImage).assetName;
    }

    final pool = kMascotPool[RiskBand.moderate]!;
    final first = asset();
    expect(pool, contains(first));

    await tester.tap(find.byKey(const Key('mascot-tap-target')));
    await tester.pumpAndSettle();
    final second = asset();
    expect(pool, contains(second));
    expect(second, isNot(first), reason: 'tap advances within the pool');

    await tester.tap(find.byKey(const Key('mascot-tap-target')));
    await tester.pumpAndSettle();
    expect(asset(), isNot(second), reason: 'second tap advances again');
  });

  testWidgets('stale cycle (yesterday key) is inert — mascot uses offset 0', (tester) async {
    final band = RiskBand.high;
    final today = _ass(band);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
    ]);
    // A cycle entry keyed to yesterday is stale and must be ignored.
    final staleEntry = (
      dateKey: mascotDateKey(DateTime.now().subtract(const Duration(days: 1))),
      band: band,
      offset: 2,
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
        tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(RiskBand.low))),
        mascotCycleProvider.overrideWith((_) => staleEntry),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    ));
    await tester.pump();

    final img = tester.widget<Image>(find.descendant(
        of: find.byType(MascotWidget), matching: find.byType(Image)));
    final renderedAsset = (img.image as AssetImage).assetName;
    // Stale entry → offset 0 → daily seeded pick, same as mascotAssetFor(band).
    expect(renderedAsset, mascotAssetFor(band));
  });

  testWidgets('band-mismatched cycle entry is inert — mascot uses offset 0', (tester) async {
    final band = RiskBand.moderate;
    final today = _ass(band);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
    ]);
    // A cycle entry with a different band is stale for this rendering context.
    final mismatchedEntry = (
      dateKey: mascotDateKey(DateTime.now()),
      band: RiskBand.high, // does not match rendered band
      offset: 2,
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
        tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(RiskBand.low))),
        mascotCycleProvider.overrideWith((_) => mismatchedEntry),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    ));
    await tester.pump();

    final img = tester.widget<Image>(find.descendant(
        of: find.byType(MascotWidget), matching: find.byType(Image)));
    final renderedAsset = (img.image as AssetImage).assetName;
    expect(renderedAsset, mascotAssetFor(band));
  });

  testWidgets('debug band override changes the mascot band', (tester) async {
    final today = _ass(RiskBand.low);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
        tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(RiskBand.low))),
        debugBandOverrideProvider.overrideWith((_) => RiskBand.veryHigh),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    ));
    await tester.pump();

    final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
    expect(mascot.band, RiskBand.veryHigh);
  });
}
