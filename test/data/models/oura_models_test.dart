import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/models/oura_models.dart';
import 'dart:convert';

void main() {
  group('OuraSleepData', () {
    test('parses sleep JSON response', () {
      final json = jsonDecode('''
        {
          "data": [
            {
              "id": "sleep-123",
              "day": "2026-06-14",
              "lowest_heart_rate": 48,
              "restless_periods": 2,
              "average_heart_rate": 58.5,
              "average_hrv": 45,
              "timestamp": "2026-06-14T08:30:00+00:00"
            }
          ]
        }
      ''');

      final data = OuraSleepData.fromJson(json);
      expect(data.records.length, 1);
      expect(data.records[0].lowestHeartRate, 48);
      expect(data.records[0].restlessPeriods, 2);
    });
  });

  group('OuraDailySleepData', () {
    test('parses daily sleep JSON response', () {
      final json = jsonDecode('''
        {
          "data": [
            {
              "id": "daily-sleep-123",
              "day": "2026-06-14",
              "score": 82,
              "timestamp": "2026-06-14T00:00:00+00:00"
            }
          ]
        }
      ''');

      final data = OuraDailySleepData.fromJson(json);
      expect(data.records.length, 1);
      expect(data.records[0].score, 82);
    });
  });

  group('OuraActivityData', () {
    test('parses activity JSON response', () {
      final json = jsonDecode('''
        {
          "data": [
            {
              "id": "activity-123",
              "day": "2026-06-14",
              "score": 85,
              "timestamp": "2026-06-14T00:00:00+00:00"
            }
          ]
        }
      ''');

      final data = OuraActivityData.fromJson(json);
      expect(data.records.length, 1);
      expect(data.records[0].score, 85);
    });
  });

  group('OuraReadinessData', () {
    test('parses readiness JSON response', () {
      final json = jsonDecode('''
        {
          "data": [
            {
              "id": "readiness-123",
              "day": "2026-06-14",
              "score": 78,
              "temperature_deviation": -0.2,
              "timestamp": "2026-06-14T00:00:00+00:00"
            }
          ]
        }
      ''');

      final data = OuraReadinessData.fromJson(json);
      expect(data.records.length, 1);
      expect(data.records[0].score, 78);
      expect(data.records[0].temperatureDeviation, -0.2);
    });
  });
}
