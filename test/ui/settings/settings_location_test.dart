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
}
