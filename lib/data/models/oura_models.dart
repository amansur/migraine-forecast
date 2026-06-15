class OuraSleepRecord {
  final String id;
  final String day;
  final int? lowestHeartRate;
  final int? restlessPeriods;
  final double? averageHeartRate;
  final int? averageHrv;
  final String timestamp;

  OuraSleepRecord({
    required this.id,
    required this.day,
    this.lowestHeartRate,
    this.restlessPeriods,
    this.averageHeartRate,
    this.averageHrv,
    required this.timestamp,
  });

  factory OuraSleepRecord.fromJson(Map<String, dynamic> json) {
    return OuraSleepRecord(
      id: json['id'] as String,
      day: json['day'] as String,
      lowestHeartRate: (json['lowest_heart_rate'] as num?)?.toInt(),
      restlessPeriods: (json['restless_periods'] as num?)?.toInt(),
      averageHeartRate: (json['average_heart_rate'] as num?)?.toDouble(),
      averageHrv: (json['average_hrv'] as num?)?.toInt(),
      timestamp: json['timestamp'] as String,
    );
  }
}

class OuraSleepData {
  final List<OuraSleepRecord> records;

  OuraSleepData({required this.records});

  factory OuraSleepData.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('data')) {
      throw FormatException('Oura response missing "data" array');
    }
    final data = json['data'] as List<dynamic>? ?? [];
    return OuraSleepData(
      records: data.map((e) => OuraSleepRecord.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class OuraDailySleepRecord {
  final String id;
  final String day;
  final int? score;
  final String timestamp;

  OuraDailySleepRecord({
    required this.id,
    required this.day,
    this.score,
    required this.timestamp,
  });

  factory OuraDailySleepRecord.fromJson(Map<String, dynamic> json) {
    return OuraDailySleepRecord(
      id: json['id'] as String,
      day: json['day'] as String,
      score: (json['score'] as num?)?.toInt(),
      timestamp: json['timestamp'] as String,
    );
  }
}

class OuraDailySleepData {
  final List<OuraDailySleepRecord> records;

  OuraDailySleepData({required this.records});

  factory OuraDailySleepData.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('data')) {
      throw FormatException('Oura response missing "data" array');
    }
    final data = json['data'] as List<dynamic>? ?? [];
    return OuraDailySleepData(
      records: data.map((e) => OuraDailySleepRecord.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class OuraActivityRecord {
  final String id;
  final String day;
  final int? score;
  final String timestamp;

  OuraActivityRecord({
    required this.id,
    required this.day,
    this.score,
    required this.timestamp,
  });

  factory OuraActivityRecord.fromJson(Map<String, dynamic> json) {
    return OuraActivityRecord(
      id: json['id'] as String,
      day: json['day'] as String,
      score: (json['score'] as num?)?.toInt(),
      timestamp: json['timestamp'] as String,
    );
  }
}

class OuraActivityData {
  final List<OuraActivityRecord> records;

  OuraActivityData({required this.records});

  factory OuraActivityData.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('data')) {
      throw FormatException('Oura response missing "data" array');
    }
    final data = json['data'] as List<dynamic>? ?? [];
    return OuraActivityData(
      records: data.map((e) => OuraActivityRecord.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class OuraReadinessRecord {
  final String id;
  final String day;
  final int? score;
  final double? temperatureDeviation;
  final String timestamp;

  OuraReadinessRecord({
    required this.id,
    required this.day,
    this.score,
    this.temperatureDeviation,
    required this.timestamp,
  });

  factory OuraReadinessRecord.fromJson(Map<String, dynamic> json) {
    return OuraReadinessRecord(
      id: json['id'] as String,
      day: json['day'] as String,
      score: (json['score'] as num?)?.toInt(),
      temperatureDeviation: (json['temperature_deviation'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as String,
    );
  }
}

class OuraReadinessData {
  final List<OuraReadinessRecord> records;

  OuraReadinessData({required this.records});

  factory OuraReadinessData.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('data')) {
      throw FormatException('Oura response missing "data" array');
    }
    final data = json['data'] as List<dynamic>? ?? [];
    return OuraReadinessData(
      records: data.map((e) => OuraReadinessRecord.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
