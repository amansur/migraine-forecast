import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/models/oura_models.dart';
import 'package:migraine_forecast/data/sources/oura_api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('OuraApiClient', () {
    test('parses successful 200 response from getSleep', () async {
      final mockClient = MockHttpClient();
      final responseBody = '''
      {
        "data": [
          {
            "id": "sleep-001",
            "day": "2024-01-01",
            "lowest_heart_rate": 45,
            "restless_periods": 2,
            "average_heart_rate": 52.5,
            "average_hrv": 35,
            "timestamp": "2024-01-01T06:00:00Z"
          }
        ]
      }
      ''';

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(responseBody, 200));

      final client = OuraApiClient(tokenProvider: () async => 'test-token', httpClient: mockClient);
      final result = await client.getSleep(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 2),
      );

      expect(result, isA<OuraSleepData>());
      expect(result.records, hasLength(1));
      expect(result.records.first.id, 'sleep-001');
      expect(result.records.first.lowestHeartRate, 45);
      expect(result.records.first.averageHeartRate, 52.5);
    });

    test('includes Authorization header in requests', () async {
      final mockClient = MockHttpClient();
      final responseBody = '{"data": []}';

      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => http.Response(responseBody, 200));

      final client = OuraApiClient(tokenProvider: () async => 'my-secret-token', httpClient: mockClient);
      await client.getDailySleep(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 2),
      );

      verify(() => mockClient.get(
            any(),
            headers: {
              'Authorization': 'Bearer my-secret-token',
              'Content-Type': 'application/json',
            },
          )).called(1);
    });
  });
}
