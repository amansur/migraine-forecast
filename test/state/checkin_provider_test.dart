import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/state/checkin_provider.dart';
import 'package:migraine_forecast/state/providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  DateTime yesterdayKey() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
  }

  setUp(() {
    db = AppDatabase.memory();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<void> insertAssessment(String band) async {
    await db.into(db.riskAssessments).insert(RiskAssessmentsCompanion.insert(
          targetDate: yesterdayKey(),
          horizon: 'today',
          score: band == 'high' ? 70 : 10,
          band: band,
          computedAt: yesterdayKey(),
          configVersion: 2,
          contributorsJson: jsonEncode([]),
        ));
  }

  test('prompts after a high-risk yesterday with no attack and no answer', () async {
    await insertAssessment('high');
    final prompt = await container.read(checkinPromptProvider.future);
    expect(prompt, yesterdayKey());
  });

  test('no prompt after a low-risk yesterday', () async {
    await insertAssessment('low');
    expect(await container.read(checkinPromptProvider.future), isNull);
  });

  test('no prompt when an attack was already logged yesterday', () async {
    await insertAssessment('high');
    final now = DateTime.now();
    await db.into(db.attacks).insert(AttacksCompanion.insert(
        startedAt: DateTime(now.year, now.month, now.day, 12)
            .subtract(const Duration(days: 1)),
        severity: 5));
    expect(await container.read(checkinPromptProvider.future), isNull);
  });

  test('no prompt once the check-in was answered', () async {
    await insertAssessment('high');
    await db.into(db.dayCheckins).insert(DayCheckinsCompanion.insert(
          day: yesterdayKey(),
          hadAttack: false,
          answeredAt: DateTime.now().toUtc(),
        ));
    expect(await container.read(checkinPromptProvider.future), isNull);
  });

  test('no prompt without any assessment for yesterday', () async {
    expect(await container.read(checkinPromptProvider.future), isNull);
  });
}
