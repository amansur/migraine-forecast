import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_geocoder.dart';
import 'package:migraine_forecast/ui/common/location_search_dialog.dart';

OpenMeteoGeocoder _stubGeocoder() => OpenMeteoGeocoder(MockClient((_) async =>
    http.Response(
        '{"results":[{"name":"Reno","admin1":"Nevada","country":"United States","latitude":39.5,"longitude":-119.8}]}',
        200)));

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

  testWidgets('OK commits Automatic (invokes onUseAuto) and closes',
      (tester) async {
    var used = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => LocationSearchDialog(
                geocoder: _stubGeocoder(),
                isCurrentlyAuto: true, // opens on Automatic
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

    // Nothing applied just by opening.
    expect(used, isFalse);
    await tester.tap(find.byKey(const Key('location-ok')));
    await tester.pumpAndSettle();

    expect(used, isTrue);
    expect(find.byKey(const Key('location-mode-toggle')), findsNothing);
  });

  testWidgets('OK is disabled in Manual until a result is selected',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocationSearchDialog(
          geocoder: _stubGeocoder(),
          isCurrentlyAuto: false, // Manual
          onUseAuto: () {},
          onPick: (_) {},
        ),
      ),
    ));

    final okButton = tester.widget<FilledButton>(find.byKey(const Key('location-ok')));
    expect(okButton.onPressed, isNull); // disabled — no selection yet
  });

  testWidgets('search, select a result, OK invokes onPick with it',
      (tester) async {
    GeocodingResult? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocationSearchDialog(
          geocoder: _stubGeocoder(),
          isCurrentlyAuto: false,
          onUseAuto: () {},
          onPick: (r) => picked = r,
        ),
      ),
    ));

    await tester.enterText(
        find.byType(TextField), 'Reno');
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    // Result appears; pick it.
    await tester.tap(find.text('Reno, Nevada, United States'));
    await tester.pumpAndSettle();

    // OK now enabled; commit.
    await tester.tap(find.byKey(const Key('location-ok')));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.name, 'Reno');
    expect(picked!.lat, 39.5);
  });
}
