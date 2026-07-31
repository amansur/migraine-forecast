import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_geocoder.dart';
import 'package:migraine_forecast/ui/common/location_search_dialog.dart';

void main() {
  testWidgets('dialog has neutral hint and honors initialQuery', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocationSearchDialog(
          geocoder: OpenMeteoGeocoder(http.Client()),
          initialQuery: 'Oakland, California',
          onPick: (_) {},
        ),
      ),
    ));

    // Pre-filled value is shown.
    expect(find.text('Oakland, California'), findsOneWidget);
    // The misleading hardcoded default is gone.
    expect(find.text('San Francisco, CA'), findsNothing);
  });

  testWidgets('dialog shows neutral hint when field is empty', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocationSearchDialog(
          geocoder: OpenMeteoGeocoder(http.Client()),
          onPick: (_) {},
        ),
      ),
    ));

    expect(find.text('e.g. city, ZIP, or country'), findsOneWidget);
    expect(find.text('San Francisco, CA'), findsNothing);
  });

  testWidgets('no auto option when onUseAuto is not provided', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocationSearchDialog(
          geocoder: OpenMeteoGeocoder(http.Client()),
          onPick: (_) {},
        ),
      ),
    ));
    expect(find.byKey(const Key('use-auto-location')), findsNothing);
  });

  testWidgets('tapping the auto option invokes onUseAuto and closes',
      (tester) async {
    var used = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => LocationSearchDialog(
                geocoder: OpenMeteoGeocoder(http.Client()),
                isCurrentlyAuto: false,
                onUseAuto: () => used = true,
                onPick: (_) {},
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Use my current location (GPS)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('use-auto-location')));
    await tester.pumpAndSettle();

    expect(used, isTrue);
    // Dialog closed.
    expect(find.byKey(const Key('use-auto-location')), findsNothing);
  });

  testWidgets('auto option shows as active and is not tappable when current',
      (tester) async {
    var used = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocationSearchDialog(
          geocoder: OpenMeteoGeocoder(http.Client()),
          isCurrentlyAuto: true,
          onUseAuto: () => used = true,
          onPick: (_) {},
        ),
      ),
    ));

    expect(find.text('Currently active'), findsOneWidget);
    await tester.tap(find.byKey(const Key('use-auto-location')));
    await tester.pump();
    expect(used, isFalse); // disabled when already auto
  });
}
