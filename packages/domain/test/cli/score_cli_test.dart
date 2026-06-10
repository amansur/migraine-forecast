@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('CLI scores a high-risk context against the bundled config', () async {
    const cfgPath = '../../assets/rules_config_v1.json';
    final ctx = {
      'now': '2026-06-10T06:00:00Z',
      'targetDate': '2026-06-10T00:00:00Z',
      'horizon': 'today',
      'weather': [
        {'at': '2026-06-10T06:00:00Z', 'pressureMsl': 1020, 'temperatureC': 18, 'humidityPct': 50},
        {'at': '2026-06-11T06:00:00Z', 'pressureMsl': 1006, 'temperatureC': 19, 'humidityPct': 55},
      ],
      'health': {
        'sleep': [
          {
            'night': '2026-06-09T00:00:00Z',
            'totalMinutes': 270,
            'efficiency': 0.78,
            'sleepStart': '2026-06-10T01:00:00Z',
          },
        ],
        'hrv': [{'at': '2026-06-10T06:00:00Z', 'rmssdMs': 30}],
      },
      'journal': [
        {'at': '2026-06-09T22:00:00Z', 'kind': 'alcohol', 'payload': {'units': 3.0}},
        {'at': '2026-06-10T02:00:00Z', 'kind': 'stress', 'payload': {'rating': 5}},
      ],
      'attacks': [],
      'baselines': {'sleepMedianMinutes': 420, 'hrvRmssd': 50},
      'userFlags': {
        'flagged': ['pressure_drop', 'sleep_deficit', 'alcohol', 'stress', 'hrv_letdown'],
        'overrides': {}
      }
    };

    final tmp = await File('${Directory.systemTemp.path}/ctx.json').create();
    await tmp.writeAsString(jsonEncode(ctx));

    final result = await Process.run('dart', ['run', 'bin/score_cli.dart', cfgPath, tmp.path]);
    expect(result.exitCode, 0, reason: 'stderr: ${result.stderr}');
    final out = jsonDecode(result.stdout as String) as Map<String, Object?>;
    expect((out['score'] as num).toInt(), greaterThan(50));
    expect(out['band'], anyOf('high', 'veryHigh'));
  }, timeout: const Timeout(Duration(seconds: 30)));
}
