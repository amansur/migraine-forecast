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

  testWidgets('no mode toggle when onUseAuto is not provided', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocationSearchDialog(
          geocoder: OpenMeteoGeocoder(http.Client()),
          onPick: (_) {},
        ),
      ),
    ));
    // No toggle → search field is shown directly.
    expect(find.byKey(const Key('location-mode-toggle')), findsNothing);
    expect(find.text('City, state, country or postal code'), findsOneWidget);
  });

  testWidgets('opens on Automatic and hides the search field', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocationSearchDialog(
          geocoder: OpenMeteoGeocoder(http.Client()),
          isCurrentlyAuto: true,
          onUseAuto: () {},
          onPick: (_) {},
        ),
      ),
    ));
    expect(find.byKey(const Key('location-mode-toggle')), findsOneWidget);
    // Auto is selected → no search field yet.
    expect(find.text('City, state, country or postal code'), findsNothing);
  });

  testWidgets('switching to Manual reveals the search field', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocationSearchDialog(
          geocoder: OpenMeteoGeocoder(http.Client()),
          isCurrentlyAuto: true,
          onUseAuto: () {},
          onPick: (_) {},
        ),
      ),
    ));
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    expect(find.text('City, state, country or postal code'), findsOneWidget);
  });

  testWidgets('selecting Automatic invokes onUseAuto and closes',
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
                isCurrentlyAuto: false, // opens on Manual
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
    // Opens on Manual (search visible).
    expect(find.text('City, state, country or postal code'), findsOneWidget);

    await tester.tap(find.text('Automatic'));
    await tester.pumpAndSettle();

    expect(used, isTrue);
    // Dialog closed.
    expect(find.byKey(const Key('location-mode-toggle')), findsNothing);
  });
}
