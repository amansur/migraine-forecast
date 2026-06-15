// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AttacksTable extends Attacks with TableInfo<$AttacksTable, Attack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _riskAssessmentIdMeta = const VerificationMeta(
    'riskAssessmentId',
  );
  @override
  late final GeneratedColumn<int> riskAssessmentId = GeneratedColumn<int>(
    'risk_assessment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inProgressMeta = const VerificationMeta(
    'inProgress',
  );
  @override
  late final GeneratedColumn<bool> inProgress = GeneratedColumn<bool>(
    'in_progress',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_progress" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    severity,
    notes,
    riskAssessmentId,
    inProgress,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attacks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('risk_assessment_id')) {
      context.handle(
        _riskAssessmentIdMeta,
        riskAssessmentId.isAcceptableOrUnknown(
          data['risk_assessment_id']!,
          _riskAssessmentIdMeta,
        ),
      );
    }
    if (data.containsKey('in_progress')) {
      context.handle(
        _inProgressMeta,
        inProgress.isAcceptableOrUnknown(data['in_progress']!, _inProgressMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attack(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}severity'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      riskAssessmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}risk_assessment_id'],
      ),
      inProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_progress'],
      )!,
    );
  }

  @override
  $AttacksTable createAlias(String alias) {
    return $AttacksTable(attachedDatabase, alias);
  }
}

class Attack extends DataClass implements Insertable<Attack> {
  final int id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int severity;
  final String? notes;
  final int? riskAssessmentId;
  final bool inProgress;
  const Attack({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.severity,
    this.notes,
    this.riskAssessmentId,
    required this.inProgress,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['severity'] = Variable<int>(severity);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || riskAssessmentId != null) {
      map['risk_assessment_id'] = Variable<int>(riskAssessmentId);
    }
    map['in_progress'] = Variable<bool>(inProgress);
    return map;
  }

  AttacksCompanion toCompanion(bool nullToAbsent) {
    return AttacksCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      severity: Value(severity),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      riskAssessmentId: riskAssessmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(riskAssessmentId),
      inProgress: Value(inProgress),
    );
  }

  factory Attack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attack(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      severity: serializer.fromJson<int>(json['severity']),
      notes: serializer.fromJson<String?>(json['notes']),
      riskAssessmentId: serializer.fromJson<int?>(json['riskAssessmentId']),
      inProgress: serializer.fromJson<bool>(json['inProgress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'severity': serializer.toJson<int>(severity),
      'notes': serializer.toJson<String?>(notes),
      'riskAssessmentId': serializer.toJson<int?>(riskAssessmentId),
      'inProgress': serializer.toJson<bool>(inProgress),
    };
  }

  Attack copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? severity,
    Value<String?> notes = const Value.absent(),
    Value<int?> riskAssessmentId = const Value.absent(),
    bool? inProgress,
  }) => Attack(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    severity: severity ?? this.severity,
    notes: notes.present ? notes.value : this.notes,
    riskAssessmentId: riskAssessmentId.present
        ? riskAssessmentId.value
        : this.riskAssessmentId,
    inProgress: inProgress ?? this.inProgress,
  );
  Attack copyWithCompanion(AttacksCompanion data) {
    return Attack(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      severity: data.severity.present ? data.severity.value : this.severity,
      notes: data.notes.present ? data.notes.value : this.notes,
      riskAssessmentId: data.riskAssessmentId.present
          ? data.riskAssessmentId.value
          : this.riskAssessmentId,
      inProgress: data.inProgress.present
          ? data.inProgress.value
          : this.inProgress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attack(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('severity: $severity, ')
          ..write('notes: $notes, ')
          ..write('riskAssessmentId: $riskAssessmentId, ')
          ..write('inProgress: $inProgress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    severity,
    notes,
    riskAssessmentId,
    inProgress,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attack &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.severity == this.severity &&
          other.notes == this.notes &&
          other.riskAssessmentId == this.riskAssessmentId &&
          other.inProgress == this.inProgress);
}

class AttacksCompanion extends UpdateCompanion<Attack> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> severity;
  final Value<String?> notes;
  final Value<int?> riskAssessmentId;
  final Value<bool> inProgress;
  const AttacksCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.severity = const Value.absent(),
    this.notes = const Value.absent(),
    this.riskAssessmentId = const Value.absent(),
    this.inProgress = const Value.absent(),
  });
  AttacksCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required int severity,
    this.notes = const Value.absent(),
    this.riskAssessmentId = const Value.absent(),
    this.inProgress = const Value.absent(),
  }) : startedAt = Value(startedAt),
       severity = Value(severity);
  static Insertable<Attack> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? severity,
    Expression<String>? notes,
    Expression<int>? riskAssessmentId,
    Expression<bool>? inProgress,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (severity != null) 'severity': severity,
      if (notes != null) 'notes': notes,
      if (riskAssessmentId != null) 'risk_assessment_id': riskAssessmentId,
      if (inProgress != null) 'in_progress': inProgress,
    });
  }

  AttacksCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? severity,
    Value<String?>? notes,
    Value<int?>? riskAssessmentId,
    Value<bool>? inProgress,
  }) {
    return AttacksCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      riskAssessmentId: riskAssessmentId ?? this.riskAssessmentId,
      inProgress: inProgress ?? this.inProgress,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (severity.present) {
      map['severity'] = Variable<int>(severity.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (riskAssessmentId.present) {
      map['risk_assessment_id'] = Variable<int>(riskAssessmentId.value);
    }
    if (inProgress.present) {
      map['in_progress'] = Variable<bool>(inProgress.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttacksCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('severity: $severity, ')
          ..write('notes: $notes, ')
          ..write('riskAssessmentId: $riskAssessmentId, ')
          ..write('inProgress: $inProgress')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, at, kind, payloadJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalEntry extends DataClass implements Insertable<JournalEntry> {
  final int id;
  final DateTime at;
  final String kind;
  final String payloadJson;
  const JournalEntry({
    required this.id,
    required this.at,
    required this.kind,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['kind'] = Variable<String>(kind);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      at: Value(at),
      kind: Value(kind),
      payloadJson: Value(payloadJson),
    );
  }

  factory JournalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntry(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      kind: serializer.fromJson<String>(json['kind']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'kind': serializer.toJson<String>(kind),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  JournalEntry copyWith({
    int? id,
    DateTime? at,
    String? kind,
    String? payloadJson,
  }) => JournalEntry(
    id: id ?? this.id,
    at: at ?? this.at,
    kind: kind ?? this.kind,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  JournalEntry copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntry(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      kind: data.kind.present ? data.kind.value : this.kind,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntry(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, kind, payloadJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntry &&
          other.id == this.id &&
          other.at == this.at &&
          other.kind == this.kind &&
          other.payloadJson == this.payloadJson);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntry> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> kind;
  final Value<String> payloadJson;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.kind = const Value.absent(),
    this.payloadJson = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String kind,
    required String payloadJson,
  }) : at = Value(at),
       kind = Value(kind),
       payloadJson = Value(payloadJson);
  static Insertable<JournalEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? kind,
    Expression<String>? payloadJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (kind != null) 'kind': kind,
      if (payloadJson != null) 'payload_json': payloadJson,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? kind,
    Value<String>? payloadJson,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      kind: kind ?? this.kind,
      payloadJson: payloadJson ?? this.payloadJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('kind: $kind, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }
}

class $WeatherSnapshotsTable extends WeatherSnapshots
    with TableInfo<$WeatherSnapshotsTable, WeatherSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _forecastJsonMeta = const VerificationMeta(
    'forecastJson',
  );
  @override
  late final GeneratedColumn<String> forecastJson = GeneratedColumn<String>(
    'forecast_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _airQualityJsonMeta = const VerificationMeta(
    'airQualityJson',
  );
  @override
  late final GeneratedColumn<String> airQualityJson = GeneratedColumn<String>(
    'air_quality_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('forecast'),
  );
  static const VerificationMeta _coverageStartMeta = const VerificationMeta(
    'coverageStart',
  );
  @override
  late final GeneratedColumn<DateTime> coverageStart =
      GeneratedColumn<DateTime>(
        'coverage_start',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _coverageEndMeta = const VerificationMeta(
    'coverageEnd',
  );
  @override
  late final GeneratedColumn<DateTime> coverageEnd = GeneratedColumn<DateTime>(
    'coverage_end',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fetchedAt,
    lat,
    lon,
    forecastJson,
    airQualityJson,
    source,
    coverageStart,
    coverageEnd,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('forecast_json')) {
      context.handle(
        _forecastJsonMeta,
        forecastJson.isAcceptableOrUnknown(
          data['forecast_json']!,
          _forecastJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_forecastJsonMeta);
    }
    if (data.containsKey('air_quality_json')) {
      context.handle(
        _airQualityJsonMeta,
        airQualityJson.isAcceptableOrUnknown(
          data['air_quality_json']!,
          _airQualityJsonMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('coverage_start')) {
      context.handle(
        _coverageStartMeta,
        coverageStart.isAcceptableOrUnknown(
          data['coverage_start']!,
          _coverageStartMeta,
        ),
      );
    }
    if (data.containsKey('coverage_end')) {
      context.handle(
        _coverageEndMeta,
        coverageEnd.isAcceptableOrUnknown(
          data['coverage_end']!,
          _coverageEndMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeatherSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      forecastJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forecast_json'],
      )!,
      airQualityJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}air_quality_json'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      coverageStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}coverage_start'],
      ),
      coverageEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}coverage_end'],
      ),
    );
  }

  @override
  $WeatherSnapshotsTable createAlias(String alias) {
    return $WeatherSnapshotsTable(attachedDatabase, alias);
  }
}

class WeatherSnapshot extends DataClass implements Insertable<WeatherSnapshot> {
  final int id;
  final DateTime fetchedAt;
  final double lat;
  final double lon;
  final String forecastJson;
  final String? airQualityJson;
  final String source;
  final DateTime? coverageStart;
  final DateTime? coverageEnd;
  const WeatherSnapshot({
    required this.id,
    required this.fetchedAt,
    required this.lat,
    required this.lon,
    required this.forecastJson,
    this.airQualityJson,
    required this.source,
    this.coverageStart,
    this.coverageEnd,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['forecast_json'] = Variable<String>(forecastJson);
    if (!nullToAbsent || airQualityJson != null) {
      map['air_quality_json'] = Variable<String>(airQualityJson);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || coverageStart != null) {
      map['coverage_start'] = Variable<DateTime>(coverageStart);
    }
    if (!nullToAbsent || coverageEnd != null) {
      map['coverage_end'] = Variable<DateTime>(coverageEnd);
    }
    return map;
  }

  WeatherSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return WeatherSnapshotsCompanion(
      id: Value(id),
      fetchedAt: Value(fetchedAt),
      lat: Value(lat),
      lon: Value(lon),
      forecastJson: Value(forecastJson),
      airQualityJson: airQualityJson == null && nullToAbsent
          ? const Value.absent()
          : Value(airQualityJson),
      source: Value(source),
      coverageStart: coverageStart == null && nullToAbsent
          ? const Value.absent()
          : Value(coverageStart),
      coverageEnd: coverageEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(coverageEnd),
    );
  }

  factory WeatherSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherSnapshot(
      id: serializer.fromJson<int>(json['id']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      forecastJson: serializer.fromJson<String>(json['forecastJson']),
      airQualityJson: serializer.fromJson<String?>(json['airQualityJson']),
      source: serializer.fromJson<String>(json['source']),
      coverageStart: serializer.fromJson<DateTime?>(json['coverageStart']),
      coverageEnd: serializer.fromJson<DateTime?>(json['coverageEnd']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'forecastJson': serializer.toJson<String>(forecastJson),
      'airQualityJson': serializer.toJson<String?>(airQualityJson),
      'source': serializer.toJson<String>(source),
      'coverageStart': serializer.toJson<DateTime?>(coverageStart),
      'coverageEnd': serializer.toJson<DateTime?>(coverageEnd),
    };
  }

  WeatherSnapshot copyWith({
    int? id,
    DateTime? fetchedAt,
    double? lat,
    double? lon,
    String? forecastJson,
    Value<String?> airQualityJson = const Value.absent(),
    String? source,
    Value<DateTime?> coverageStart = const Value.absent(),
    Value<DateTime?> coverageEnd = const Value.absent(),
  }) => WeatherSnapshot(
    id: id ?? this.id,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    forecastJson: forecastJson ?? this.forecastJson,
    airQualityJson: airQualityJson.present
        ? airQualityJson.value
        : this.airQualityJson,
    source: source ?? this.source,
    coverageStart: coverageStart.present
        ? coverageStart.value
        : this.coverageStart,
    coverageEnd: coverageEnd.present ? coverageEnd.value : this.coverageEnd,
  );
  WeatherSnapshot copyWithCompanion(WeatherSnapshotsCompanion data) {
    return WeatherSnapshot(
      id: data.id.present ? data.id.value : this.id,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      forecastJson: data.forecastJson.present
          ? data.forecastJson.value
          : this.forecastJson,
      airQualityJson: data.airQualityJson.present
          ? data.airQualityJson.value
          : this.airQualityJson,
      source: data.source.present ? data.source.value : this.source,
      coverageStart: data.coverageStart.present
          ? data.coverageStart.value
          : this.coverageStart,
      coverageEnd: data.coverageEnd.present
          ? data.coverageEnd.value
          : this.coverageEnd,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherSnapshot(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('forecastJson: $forecastJson, ')
          ..write('airQualityJson: $airQualityJson, ')
          ..write('source: $source, ')
          ..write('coverageStart: $coverageStart, ')
          ..write('coverageEnd: $coverageEnd')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fetchedAt,
    lat,
    lon,
    forecastJson,
    airQualityJson,
    source,
    coverageStart,
    coverageEnd,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherSnapshot &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.forecastJson == this.forecastJson &&
          other.airQualityJson == this.airQualityJson &&
          other.source == this.source &&
          other.coverageStart == this.coverageStart &&
          other.coverageEnd == this.coverageEnd);
}

class WeatherSnapshotsCompanion extends UpdateCompanion<WeatherSnapshot> {
  final Value<int> id;
  final Value<DateTime> fetchedAt;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String> forecastJson;
  final Value<String?> airQualityJson;
  final Value<String> source;
  final Value<DateTime?> coverageStart;
  final Value<DateTime?> coverageEnd;
  const WeatherSnapshotsCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.forecastJson = const Value.absent(),
    this.airQualityJson = const Value.absent(),
    this.source = const Value.absent(),
    this.coverageStart = const Value.absent(),
    this.coverageEnd = const Value.absent(),
  });
  WeatherSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime fetchedAt,
    required double lat,
    required double lon,
    required String forecastJson,
    this.airQualityJson = const Value.absent(),
    this.source = const Value.absent(),
    this.coverageStart = const Value.absent(),
    this.coverageEnd = const Value.absent(),
  }) : fetchedAt = Value(fetchedAt),
       lat = Value(lat),
       lon = Value(lon),
       forecastJson = Value(forecastJson);
  static Insertable<WeatherSnapshot> custom({
    Expression<int>? id,
    Expression<DateTime>? fetchedAt,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? forecastJson,
    Expression<String>? airQualityJson,
    Expression<String>? source,
    Expression<DateTime>? coverageStart,
    Expression<DateTime>? coverageEnd,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (forecastJson != null) 'forecast_json': forecastJson,
      if (airQualityJson != null) 'air_quality_json': airQualityJson,
      if (source != null) 'source': source,
      if (coverageStart != null) 'coverage_start': coverageStart,
      if (coverageEnd != null) 'coverage_end': coverageEnd,
    });
  }

  WeatherSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? fetchedAt,
    Value<double>? lat,
    Value<double>? lon,
    Value<String>? forecastJson,
    Value<String?>? airQualityJson,
    Value<String>? source,
    Value<DateTime?>? coverageStart,
    Value<DateTime?>? coverageEnd,
  }) {
    return WeatherSnapshotsCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      forecastJson: forecastJson ?? this.forecastJson,
      airQualityJson: airQualityJson ?? this.airQualityJson,
      source: source ?? this.source,
      coverageStart: coverageStart ?? this.coverageStart,
      coverageEnd: coverageEnd ?? this.coverageEnd,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (forecastJson.present) {
      map['forecast_json'] = Variable<String>(forecastJson.value);
    }
    if (airQualityJson.present) {
      map['air_quality_json'] = Variable<String>(airQualityJson.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (coverageStart.present) {
      map['coverage_start'] = Variable<DateTime>(coverageStart.value);
    }
    if (coverageEnd.present) {
      map['coverage_end'] = Variable<DateTime>(coverageEnd.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('forecastJson: $forecastJson, ')
          ..write('airQualityJson: $airQualityJson, ')
          ..write('source: $source, ')
          ..write('coverageStart: $coverageStart, ')
          ..write('coverageEnd: $coverageEnd')
          ..write(')'))
        .toString();
  }
}

class $BaselinesKvTable extends BaselinesKv
    with TableInfo<$BaselinesKvTable, BaselinesKvData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BaselinesKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'baselines_kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<BaselinesKvData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  BaselinesKvData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BaselinesKvData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BaselinesKvTable createAlias(String alias) {
    return $BaselinesKvTable(attachedDatabase, alias);
  }
}

class BaselinesKvData extends DataClass implements Insertable<BaselinesKvData> {
  final String key;
  final double value;
  final DateTime updatedAt;
  const BaselinesKvData({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<double>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BaselinesKvCompanion toCompanion(bool nullToAbsent) {
    return BaselinesKvCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory BaselinesKvData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BaselinesKvData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<double>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<double>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BaselinesKvData copyWith({String? key, double? value, DateTime? updatedAt}) =>
      BaselinesKvData(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BaselinesKvData copyWithCompanion(BaselinesKvCompanion data) {
    return BaselinesKvData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BaselinesKvData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BaselinesKvData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class BaselinesKvCompanion extends UpdateCompanion<BaselinesKvData> {
  final Value<String> key;
  final Value<double> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BaselinesKvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BaselinesKvCompanion.insert({
    required String key,
    required double value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<BaselinesKvData> custom({
    Expression<String>? key,
    Expression<double>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BaselinesKvCompanion copyWith({
    Value<String>? key,
    Value<double>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BaselinesKvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BaselinesKvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserTriggerFlagsTblTable extends UserTriggerFlagsTbl
    with TableInfo<$UserTriggerFlagsTblTable, UserTriggerFlagsTblData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTriggerFlagsTblTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _moduleIdMeta = const VerificationMeta(
    'moduleId',
  );
  @override
  late final GeneratedColumn<String> moduleId = GeneratedColumn<String>(
    'module_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flaggedMeta = const VerificationMeta(
    'flagged',
  );
  @override
  late final GeneratedColumn<bool> flagged = GeneratedColumn<bool>(
    'flagged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("flagged" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _weightOverrideMeta = const VerificationMeta(
    'weightOverride',
  );
  @override
  late final GeneratedColumn<double> weightOverride = GeneratedColumn<double>(
    'weight_override',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [moduleId, flagged, weightOverride];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_trigger_flags';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserTriggerFlagsTblData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('module_id')) {
      context.handle(
        _moduleIdMeta,
        moduleId.isAcceptableOrUnknown(data['module_id']!, _moduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleIdMeta);
    }
    if (data.containsKey('flagged')) {
      context.handle(
        _flaggedMeta,
        flagged.isAcceptableOrUnknown(data['flagged']!, _flaggedMeta),
      );
    }
    if (data.containsKey('weight_override')) {
      context.handle(
        _weightOverrideMeta,
        weightOverride.isAcceptableOrUnknown(
          data['weight_override']!,
          _weightOverrideMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {moduleId};
  @override
  UserTriggerFlagsTblData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserTriggerFlagsTblData(
      moduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module_id'],
      )!,
      flagged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}flagged'],
      )!,
      weightOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_override'],
      )!,
    );
  }

  @override
  $UserTriggerFlagsTblTable createAlias(String alias) {
    return $UserTriggerFlagsTblTable(attachedDatabase, alias);
  }
}

class UserTriggerFlagsTblData extends DataClass
    implements Insertable<UserTriggerFlagsTblData> {
  final String moduleId;
  final bool flagged;
  final double weightOverride;
  const UserTriggerFlagsTblData({
    required this.moduleId,
    required this.flagged,
    required this.weightOverride,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['module_id'] = Variable<String>(moduleId);
    map['flagged'] = Variable<bool>(flagged);
    map['weight_override'] = Variable<double>(weightOverride);
    return map;
  }

  UserTriggerFlagsTblCompanion toCompanion(bool nullToAbsent) {
    return UserTriggerFlagsTblCompanion(
      moduleId: Value(moduleId),
      flagged: Value(flagged),
      weightOverride: Value(weightOverride),
    );
  }

  factory UserTriggerFlagsTblData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserTriggerFlagsTblData(
      moduleId: serializer.fromJson<String>(json['moduleId']),
      flagged: serializer.fromJson<bool>(json['flagged']),
      weightOverride: serializer.fromJson<double>(json['weightOverride']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'moduleId': serializer.toJson<String>(moduleId),
      'flagged': serializer.toJson<bool>(flagged),
      'weightOverride': serializer.toJson<double>(weightOverride),
    };
  }

  UserTriggerFlagsTblData copyWith({
    String? moduleId,
    bool? flagged,
    double? weightOverride,
  }) => UserTriggerFlagsTblData(
    moduleId: moduleId ?? this.moduleId,
    flagged: flagged ?? this.flagged,
    weightOverride: weightOverride ?? this.weightOverride,
  );
  UserTriggerFlagsTblData copyWithCompanion(UserTriggerFlagsTblCompanion data) {
    return UserTriggerFlagsTblData(
      moduleId: data.moduleId.present ? data.moduleId.value : this.moduleId,
      flagged: data.flagged.present ? data.flagged.value : this.flagged,
      weightOverride: data.weightOverride.present
          ? data.weightOverride.value
          : this.weightOverride,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserTriggerFlagsTblData(')
          ..write('moduleId: $moduleId, ')
          ..write('flagged: $flagged, ')
          ..write('weightOverride: $weightOverride')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(moduleId, flagged, weightOverride);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserTriggerFlagsTblData &&
          other.moduleId == this.moduleId &&
          other.flagged == this.flagged &&
          other.weightOverride == this.weightOverride);
}

class UserTriggerFlagsTblCompanion
    extends UpdateCompanion<UserTriggerFlagsTblData> {
  final Value<String> moduleId;
  final Value<bool> flagged;
  final Value<double> weightOverride;
  final Value<int> rowid;
  const UserTriggerFlagsTblCompanion({
    this.moduleId = const Value.absent(),
    this.flagged = const Value.absent(),
    this.weightOverride = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserTriggerFlagsTblCompanion.insert({
    required String moduleId,
    this.flagged = const Value.absent(),
    this.weightOverride = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : moduleId = Value(moduleId);
  static Insertable<UserTriggerFlagsTblData> custom({
    Expression<String>? moduleId,
    Expression<bool>? flagged,
    Expression<double>? weightOverride,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (moduleId != null) 'module_id': moduleId,
      if (flagged != null) 'flagged': flagged,
      if (weightOverride != null) 'weight_override': weightOverride,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserTriggerFlagsTblCompanion copyWith({
    Value<String>? moduleId,
    Value<bool>? flagged,
    Value<double>? weightOverride,
    Value<int>? rowid,
  }) {
    return UserTriggerFlagsTblCompanion(
      moduleId: moduleId ?? this.moduleId,
      flagged: flagged ?? this.flagged,
      weightOverride: weightOverride ?? this.weightOverride,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (moduleId.present) {
      map['module_id'] = Variable<String>(moduleId.value);
    }
    if (flagged.present) {
      map['flagged'] = Variable<bool>(flagged.value);
    }
    if (weightOverride.present) {
      map['weight_override'] = Variable<double>(weightOverride.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserTriggerFlagsTblCompanion(')
          ..write('moduleId: $moduleId, ')
          ..write('flagged: $flagged, ')
          ..write('weightOverride: $weightOverride, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RiskAssessmentsTable extends RiskAssessments
    with TableInfo<$RiskAssessmentsTable, RiskAssessment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RiskAssessmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _horizonMeta = const VerificationMeta(
    'horizon',
  );
  @override
  late final GeneratedColumn<String> horizon = GeneratedColumn<String>(
    'horizon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bandMeta = const VerificationMeta('band');
  @override
  late final GeneratedColumn<String> band = GeneratedColumn<String>(
    'band',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configVersionMeta = const VerificationMeta(
    'configVersion',
  );
  @override
  late final GeneratedColumn<int> configVersion = GeneratedColumn<int>(
    'config_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contributorsJsonMeta = const VerificationMeta(
    'contributorsJson',
  );
  @override
  late final GeneratedColumn<String> contributorsJson = GeneratedColumn<String>(
    'contributors_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backfilledMeta = const VerificationMeta(
    'backfilled',
  );
  @override
  late final GeneratedColumn<bool> backfilled = GeneratedColumn<bool>(
    'backfilled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("backfilled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetDate,
    horizon,
    score,
    band,
    computedAt,
    configVersion,
    contributorsJson,
    backfilled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'risk_assessments';
  @override
  VerificationContext validateIntegrity(
    Insertable<RiskAssessment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('horizon')) {
      context.handle(
        _horizonMeta,
        horizon.isAcceptableOrUnknown(data['horizon']!, _horizonMeta),
      );
    } else if (isInserting) {
      context.missing(_horizonMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('band')) {
      context.handle(
        _bandMeta,
        band.isAcceptableOrUnknown(data['band']!, _bandMeta),
      );
    } else if (isInserting) {
      context.missing(_bandMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    if (data.containsKey('config_version')) {
      context.handle(
        _configVersionMeta,
        configVersion.isAcceptableOrUnknown(
          data['config_version']!,
          _configVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configVersionMeta);
    }
    if (data.containsKey('contributors_json')) {
      context.handle(
        _contributorsJsonMeta,
        contributorsJson.isAcceptableOrUnknown(
          data['contributors_json']!,
          _contributorsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contributorsJsonMeta);
    }
    if (data.containsKey('backfilled')) {
      context.handle(
        _backfilledMeta,
        backfilled.isAcceptableOrUnknown(data['backfilled']!, _backfilledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {targetDate, horizon},
  ];
  @override
  RiskAssessment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RiskAssessment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      )!,
      horizon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}horizon'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      band: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}band'],
      )!,
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}computed_at'],
      )!,
      configVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}config_version'],
      )!,
      contributorsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contributors_json'],
      )!,
      backfilled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}backfilled'],
      )!,
    );
  }

  @override
  $RiskAssessmentsTable createAlias(String alias) {
    return $RiskAssessmentsTable(attachedDatabase, alias);
  }
}

class RiskAssessment extends DataClass implements Insertable<RiskAssessment> {
  final int id;
  final DateTime targetDate;
  final String horizon;
  final int score;
  final String band;
  final DateTime computedAt;
  final int configVersion;
  final String contributorsJson;
  final bool backfilled;
  const RiskAssessment({
    required this.id,
    required this.targetDate,
    required this.horizon,
    required this.score,
    required this.band,
    required this.computedAt,
    required this.configVersion,
    required this.contributorsJson,
    required this.backfilled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_date'] = Variable<DateTime>(targetDate);
    map['horizon'] = Variable<String>(horizon);
    map['score'] = Variable<int>(score);
    map['band'] = Variable<String>(band);
    map['computed_at'] = Variable<DateTime>(computedAt);
    map['config_version'] = Variable<int>(configVersion);
    map['contributors_json'] = Variable<String>(contributorsJson);
    map['backfilled'] = Variable<bool>(backfilled);
    return map;
  }

  RiskAssessmentsCompanion toCompanion(bool nullToAbsent) {
    return RiskAssessmentsCompanion(
      id: Value(id),
      targetDate: Value(targetDate),
      horizon: Value(horizon),
      score: Value(score),
      band: Value(band),
      computedAt: Value(computedAt),
      configVersion: Value(configVersion),
      contributorsJson: Value(contributorsJson),
      backfilled: Value(backfilled),
    );
  }

  factory RiskAssessment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RiskAssessment(
      id: serializer.fromJson<int>(json['id']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      horizon: serializer.fromJson<String>(json['horizon']),
      score: serializer.fromJson<int>(json['score']),
      band: serializer.fromJson<String>(json['band']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
      configVersion: serializer.fromJson<int>(json['configVersion']),
      contributorsJson: serializer.fromJson<String>(json['contributorsJson']),
      backfilled: serializer.fromJson<bool>(json['backfilled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'horizon': serializer.toJson<String>(horizon),
      'score': serializer.toJson<int>(score),
      'band': serializer.toJson<String>(band),
      'computedAt': serializer.toJson<DateTime>(computedAt),
      'configVersion': serializer.toJson<int>(configVersion),
      'contributorsJson': serializer.toJson<String>(contributorsJson),
      'backfilled': serializer.toJson<bool>(backfilled),
    };
  }

  RiskAssessment copyWith({
    int? id,
    DateTime? targetDate,
    String? horizon,
    int? score,
    String? band,
    DateTime? computedAt,
    int? configVersion,
    String? contributorsJson,
    bool? backfilled,
  }) => RiskAssessment(
    id: id ?? this.id,
    targetDate: targetDate ?? this.targetDate,
    horizon: horizon ?? this.horizon,
    score: score ?? this.score,
    band: band ?? this.band,
    computedAt: computedAt ?? this.computedAt,
    configVersion: configVersion ?? this.configVersion,
    contributorsJson: contributorsJson ?? this.contributorsJson,
    backfilled: backfilled ?? this.backfilled,
  );
  RiskAssessment copyWithCompanion(RiskAssessmentsCompanion data) {
    return RiskAssessment(
      id: data.id.present ? data.id.value : this.id,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      horizon: data.horizon.present ? data.horizon.value : this.horizon,
      score: data.score.present ? data.score.value : this.score,
      band: data.band.present ? data.band.value : this.band,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
      configVersion: data.configVersion.present
          ? data.configVersion.value
          : this.configVersion,
      contributorsJson: data.contributorsJson.present
          ? data.contributorsJson.value
          : this.contributorsJson,
      backfilled: data.backfilled.present
          ? data.backfilled.value
          : this.backfilled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RiskAssessment(')
          ..write('id: $id, ')
          ..write('targetDate: $targetDate, ')
          ..write('horizon: $horizon, ')
          ..write('score: $score, ')
          ..write('band: $band, ')
          ..write('computedAt: $computedAt, ')
          ..write('configVersion: $configVersion, ')
          ..write('contributorsJson: $contributorsJson, ')
          ..write('backfilled: $backfilled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetDate,
    horizon,
    score,
    band,
    computedAt,
    configVersion,
    contributorsJson,
    backfilled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RiskAssessment &&
          other.id == this.id &&
          other.targetDate == this.targetDate &&
          other.horizon == this.horizon &&
          other.score == this.score &&
          other.band == this.band &&
          other.computedAt == this.computedAt &&
          other.configVersion == this.configVersion &&
          other.contributorsJson == this.contributorsJson &&
          other.backfilled == this.backfilled);
}

class RiskAssessmentsCompanion extends UpdateCompanion<RiskAssessment> {
  final Value<int> id;
  final Value<DateTime> targetDate;
  final Value<String> horizon;
  final Value<int> score;
  final Value<String> band;
  final Value<DateTime> computedAt;
  final Value<int> configVersion;
  final Value<String> contributorsJson;
  final Value<bool> backfilled;
  const RiskAssessmentsCompanion({
    this.id = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.horizon = const Value.absent(),
    this.score = const Value.absent(),
    this.band = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.configVersion = const Value.absent(),
    this.contributorsJson = const Value.absent(),
    this.backfilled = const Value.absent(),
  });
  RiskAssessmentsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime targetDate,
    required String horizon,
    required int score,
    required String band,
    required DateTime computedAt,
    required int configVersion,
    required String contributorsJson,
    this.backfilled = const Value.absent(),
  }) : targetDate = Value(targetDate),
       horizon = Value(horizon),
       score = Value(score),
       band = Value(band),
       computedAt = Value(computedAt),
       configVersion = Value(configVersion),
       contributorsJson = Value(contributorsJson);
  static Insertable<RiskAssessment> custom({
    Expression<int>? id,
    Expression<DateTime>? targetDate,
    Expression<String>? horizon,
    Expression<int>? score,
    Expression<String>? band,
    Expression<DateTime>? computedAt,
    Expression<int>? configVersion,
    Expression<String>? contributorsJson,
    Expression<bool>? backfilled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetDate != null) 'target_date': targetDate,
      if (horizon != null) 'horizon': horizon,
      if (score != null) 'score': score,
      if (band != null) 'band': band,
      if (computedAt != null) 'computed_at': computedAt,
      if (configVersion != null) 'config_version': configVersion,
      if (contributorsJson != null) 'contributors_json': contributorsJson,
      if (backfilled != null) 'backfilled': backfilled,
    });
  }

  RiskAssessmentsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? targetDate,
    Value<String>? horizon,
    Value<int>? score,
    Value<String>? band,
    Value<DateTime>? computedAt,
    Value<int>? configVersion,
    Value<String>? contributorsJson,
    Value<bool>? backfilled,
  }) {
    return RiskAssessmentsCompanion(
      id: id ?? this.id,
      targetDate: targetDate ?? this.targetDate,
      horizon: horizon ?? this.horizon,
      score: score ?? this.score,
      band: band ?? this.band,
      computedAt: computedAt ?? this.computedAt,
      configVersion: configVersion ?? this.configVersion,
      contributorsJson: contributorsJson ?? this.contributorsJson,
      backfilled: backfilled ?? this.backfilled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (horizon.present) {
      map['horizon'] = Variable<String>(horizon.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (band.present) {
      map['band'] = Variable<String>(band.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    if (configVersion.present) {
      map['config_version'] = Variable<int>(configVersion.value);
    }
    if (contributorsJson.present) {
      map['contributors_json'] = Variable<String>(contributorsJson.value);
    }
    if (backfilled.present) {
      map['backfilled'] = Variable<bool>(backfilled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RiskAssessmentsCompanion(')
          ..write('id: $id, ')
          ..write('targetDate: $targetDate, ')
          ..write('horizon: $horizon, ')
          ..write('score: $score, ')
          ..write('band: $band, ')
          ..write('computedAt: $computedAt, ')
          ..write('configVersion: $configVersion, ')
          ..write('contributorsJson: $contributorsJson, ')
          ..write('backfilled: $backfilled')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsSentTable extends NotificationsSent
    with TableInfo<$NotificationsSentTable, NotificationsSentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsSentTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _horizonMeta = const VerificationMeta(
    'horizon',
  );
  @override
  late final GeneratedColumn<String> horizon = GeneratedColumn<String>(
    'horizon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bandMeta = const VerificationMeta('band');
  @override
  late final GeneratedColumn<String> band = GeneratedColumn<String>(
    'band',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, targetDate, horizon, band, sentAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications_sent';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationsSentData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('horizon')) {
      context.handle(
        _horizonMeta,
        horizon.isAcceptableOrUnknown(data['horizon']!, _horizonMeta),
      );
    } else if (isInserting) {
      context.missing(_horizonMeta);
    }
    if (data.containsKey('band')) {
      context.handle(
        _bandMeta,
        band.isAcceptableOrUnknown(data['band']!, _bandMeta),
      );
    } else if (isInserting) {
      context.missing(_bandMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationsSentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationsSentData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      )!,
      horizon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}horizon'],
      )!,
      band: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}band'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
    );
  }

  @override
  $NotificationsSentTable createAlias(String alias) {
    return $NotificationsSentTable(attachedDatabase, alias);
  }
}

class NotificationsSentData extends DataClass
    implements Insertable<NotificationsSentData> {
  final int id;
  final DateTime targetDate;
  final String horizon;
  final String band;
  final DateTime sentAt;
  const NotificationsSentData({
    required this.id,
    required this.targetDate,
    required this.horizon,
    required this.band,
    required this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_date'] = Variable<DateTime>(targetDate);
    map['horizon'] = Variable<String>(horizon);
    map['band'] = Variable<String>(band);
    map['sent_at'] = Variable<DateTime>(sentAt);
    return map;
  }

  NotificationsSentCompanion toCompanion(bool nullToAbsent) {
    return NotificationsSentCompanion(
      id: Value(id),
      targetDate: Value(targetDate),
      horizon: Value(horizon),
      band: Value(band),
      sentAt: Value(sentAt),
    );
  }

  factory NotificationsSentData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationsSentData(
      id: serializer.fromJson<int>(json['id']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      horizon: serializer.fromJson<String>(json['horizon']),
      band: serializer.fromJson<String>(json['band']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'horizon': serializer.toJson<String>(horizon),
      'band': serializer.toJson<String>(band),
      'sentAt': serializer.toJson<DateTime>(sentAt),
    };
  }

  NotificationsSentData copyWith({
    int? id,
    DateTime? targetDate,
    String? horizon,
    String? band,
    DateTime? sentAt,
  }) => NotificationsSentData(
    id: id ?? this.id,
    targetDate: targetDate ?? this.targetDate,
    horizon: horizon ?? this.horizon,
    band: band ?? this.band,
    sentAt: sentAt ?? this.sentAt,
  );
  NotificationsSentData copyWithCompanion(NotificationsSentCompanion data) {
    return NotificationsSentData(
      id: data.id.present ? data.id.value : this.id,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      horizon: data.horizon.present ? data.horizon.value : this.horizon,
      band: data.band.present ? data.band.value : this.band,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsSentData(')
          ..write('id: $id, ')
          ..write('targetDate: $targetDate, ')
          ..write('horizon: $horizon, ')
          ..write('band: $band, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, targetDate, horizon, band, sentAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationsSentData &&
          other.id == this.id &&
          other.targetDate == this.targetDate &&
          other.horizon == this.horizon &&
          other.band == this.band &&
          other.sentAt == this.sentAt);
}

class NotificationsSentCompanion
    extends UpdateCompanion<NotificationsSentData> {
  final Value<int> id;
  final Value<DateTime> targetDate;
  final Value<String> horizon;
  final Value<String> band;
  final Value<DateTime> sentAt;
  const NotificationsSentCompanion({
    this.id = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.horizon = const Value.absent(),
    this.band = const Value.absent(),
    this.sentAt = const Value.absent(),
  });
  NotificationsSentCompanion.insert({
    this.id = const Value.absent(),
    required DateTime targetDate,
    required String horizon,
    required String band,
    required DateTime sentAt,
  }) : targetDate = Value(targetDate),
       horizon = Value(horizon),
       band = Value(band),
       sentAt = Value(sentAt);
  static Insertable<NotificationsSentData> custom({
    Expression<int>? id,
    Expression<DateTime>? targetDate,
    Expression<String>? horizon,
    Expression<String>? band,
    Expression<DateTime>? sentAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetDate != null) 'target_date': targetDate,
      if (horizon != null) 'horizon': horizon,
      if (band != null) 'band': band,
      if (sentAt != null) 'sent_at': sentAt,
    });
  }

  NotificationsSentCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? targetDate,
    Value<String>? horizon,
    Value<String>? band,
    Value<DateTime>? sentAt,
  }) {
    return NotificationsSentCompanion(
      id: id ?? this.id,
      targetDate: targetDate ?? this.targetDate,
      horizon: horizon ?? this.horizon,
      band: band ?? this.band,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (horizon.present) {
      map['horizon'] = Variable<String>(horizon.value);
    }
    if (band.present) {
      map['band'] = Variable<String>(band.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsSentCompanion(')
          ..write('id: $id, ')
          ..write('targetDate: $targetDate, ')
          ..write('horizon: $horizon, ')
          ..write('band: $band, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }
}

class $PeriodsTable extends Periods with TableInfo<$PeriodsTable, Period> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baselineSeverityMeta = const VerificationMeta(
    'baselineSeverity',
  );
  @override
  late final GeneratedColumn<int> baselineSeverity = GeneratedColumn<int>(
    'baseline_severity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    baselineSeverity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'periods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Period> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('baseline_severity')) {
      context.handle(
        _baselineSeverityMeta,
        baselineSeverity.isAcceptableOrUnknown(
          data['baseline_severity']!,
          _baselineSeverityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baselineSeverityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Period map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Period(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      baselineSeverity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}baseline_severity'],
      )!,
    );
  }

  @override
  $PeriodsTable createAlias(String alias) {
    return $PeriodsTable(attachedDatabase, alias);
  }
}

class Period extends DataClass implements Insertable<Period> {
  final int id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int baselineSeverity;
  const Period({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.baselineSeverity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['baseline_severity'] = Variable<int>(baselineSeverity);
    return map;
  }

  PeriodsCompanion toCompanion(bool nullToAbsent) {
    return PeriodsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      baselineSeverity: Value(baselineSeverity),
    );
  }

  factory Period.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Period(
      id: serializer.fromJson<int>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      baselineSeverity: serializer.fromJson<int>(json['baselineSeverity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'baselineSeverity': serializer.toJson<int>(baselineSeverity),
    };
  }

  Period copyWith({
    int? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? baselineSeverity,
  }) => Period(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    baselineSeverity: baselineSeverity ?? this.baselineSeverity,
  );
  Period copyWithCompanion(PeriodsCompanion data) {
    return Period(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      baselineSeverity: data.baselineSeverity.present
          ? data.baselineSeverity.value
          : this.baselineSeverity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Period(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('baselineSeverity: $baselineSeverity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startedAt, endedAt, baselineSeverity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Period &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.baselineSeverity == this.baselineSeverity);
}

class PeriodsCompanion extends UpdateCompanion<Period> {
  final Value<int> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> baselineSeverity;
  const PeriodsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.baselineSeverity = const Value.absent(),
  });
  PeriodsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required int baselineSeverity,
  }) : startedAt = Value(startedAt),
       baselineSeverity = Value(baselineSeverity);
  static Insertable<Period> custom({
    Expression<int>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? baselineSeverity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (baselineSeverity != null) 'baseline_severity': baselineSeverity,
    });
  }

  PeriodsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? baselineSeverity,
  }) {
    return PeriodsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      baselineSeverity: baselineSeverity ?? this.baselineSeverity,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (baselineSeverity.present) {
      map['baseline_severity'] = Variable<int>(baselineSeverity.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('baselineSeverity: $baselineSeverity')
          ..write(')'))
        .toString();
  }
}

class $PeriodDaySeveritiesTable extends PeriodDaySeverities
    with TableInfo<$PeriodDaySeveritiesTable, PeriodDaySeverity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodDaySeveritiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day, severity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_day_severities';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeriodDaySeverity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  PeriodDaySeverity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodDaySeverity(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}severity'],
      )!,
    );
  }

  @override
  $PeriodDaySeveritiesTable createAlias(String alias) {
    return $PeriodDaySeveritiesTable(attachedDatabase, alias);
  }
}

class PeriodDaySeverity extends DataClass
    implements Insertable<PeriodDaySeverity> {
  final DateTime day;
  final int severity;
  const PeriodDaySeverity({required this.day, required this.severity});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<DateTime>(day);
    map['severity'] = Variable<int>(severity);
    return map;
  }

  PeriodDaySeveritiesCompanion toCompanion(bool nullToAbsent) {
    return PeriodDaySeveritiesCompanion(
      day: Value(day),
      severity: Value(severity),
    );
  }

  factory PeriodDaySeverity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodDaySeverity(
      day: serializer.fromJson<DateTime>(json['day']),
      severity: serializer.fromJson<int>(json['severity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<DateTime>(day),
      'severity': serializer.toJson<int>(severity),
    };
  }

  PeriodDaySeverity copyWith({DateTime? day, int? severity}) =>
      PeriodDaySeverity(
        day: day ?? this.day,
        severity: severity ?? this.severity,
      );
  PeriodDaySeverity copyWithCompanion(PeriodDaySeveritiesCompanion data) {
    return PeriodDaySeverity(
      day: data.day.present ? data.day.value : this.day,
      severity: data.severity.present ? data.severity.value : this.severity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodDaySeverity(')
          ..write('day: $day, ')
          ..write('severity: $severity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, severity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodDaySeverity &&
          other.day == this.day &&
          other.severity == this.severity);
}

class PeriodDaySeveritiesCompanion extends UpdateCompanion<PeriodDaySeverity> {
  final Value<DateTime> day;
  final Value<int> severity;
  final Value<int> rowid;
  const PeriodDaySeveritiesCompanion({
    this.day = const Value.absent(),
    this.severity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeriodDaySeveritiesCompanion.insert({
    required DateTime day,
    required int severity,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       severity = Value(severity);
  static Insertable<PeriodDaySeverity> custom({
    Expression<DateTime>? day,
    Expression<int>? severity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (severity != null) 'severity': severity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeriodDaySeveritiesCompanion copyWith({
    Value<DateTime>? day,
    Value<int>? severity,
    Value<int>? rowid,
  }) {
    return PeriodDaySeveritiesCompanion(
      day: day ?? this.day,
      severity: severity ?? this.severity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (severity.present) {
      map['severity'] = Variable<int>(severity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodDaySeveritiesCompanion(')
          ..write('day: $day, ')
          ..write('severity: $severity, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ManualSleepRecordsTable extends ManualSleepRecords
    with TableInfo<$ManualSleepRecordsTable, ManualSleepRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManualSleepRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nightMeta = const VerificationMeta('night');
  @override
  late final GeneratedColumn<DateTime> night = GeneratedColumn<DateTime>(
    'night',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sleepStartMeta = const VerificationMeta(
    'sleepStart',
  );
  @override
  late final GeneratedColumn<DateTime> sleepStart = GeneratedColumn<DateTime>(
    'sleep_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSleepMinutesMeta = const VerificationMeta(
    'totalSleepMinutes',
  );
  @override
  late final GeneratedColumn<int> totalSleepMinutes = GeneratedColumn<int>(
    'total_sleep_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _efficiencyMeta = const VerificationMeta(
    'efficiency',
  );
  @override
  late final GeneratedColumn<double> efficiency = GeneratedColumn<double>(
    'efficiency',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    night,
    sleepStart,
    totalSleepMinutes,
    efficiency,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manual_sleep_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ManualSleepRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('night')) {
      context.handle(
        _nightMeta,
        night.isAcceptableOrUnknown(data['night']!, _nightMeta),
      );
    } else if (isInserting) {
      context.missing(_nightMeta);
    }
    if (data.containsKey('sleep_start')) {
      context.handle(
        _sleepStartMeta,
        sleepStart.isAcceptableOrUnknown(data['sleep_start']!, _sleepStartMeta),
      );
    } else if (isInserting) {
      context.missing(_sleepStartMeta);
    }
    if (data.containsKey('total_sleep_minutes')) {
      context.handle(
        _totalSleepMinutesMeta,
        totalSleepMinutes.isAcceptableOrUnknown(
          data['total_sleep_minutes']!,
          _totalSleepMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalSleepMinutesMeta);
    }
    if (data.containsKey('efficiency')) {
      context.handle(
        _efficiencyMeta,
        efficiency.isAcceptableOrUnknown(data['efficiency']!, _efficiencyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {night};
  @override
  ManualSleepRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManualSleepRecord(
      night: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}night'],
      )!,
      sleepStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sleep_start'],
      )!,
      totalSleepMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_sleep_minutes'],
      )!,
      efficiency: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}efficiency'],
      ),
    );
  }

  @override
  $ManualSleepRecordsTable createAlias(String alias) {
    return $ManualSleepRecordsTable(attachedDatabase, alias);
  }
}

class ManualSleepRecord extends DataClass
    implements Insertable<ManualSleepRecord> {
  final DateTime night;
  final DateTime sleepStart;
  final int totalSleepMinutes;
  final double? efficiency;
  const ManualSleepRecord({
    required this.night,
    required this.sleepStart,
    required this.totalSleepMinutes,
    this.efficiency,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['night'] = Variable<DateTime>(night);
    map['sleep_start'] = Variable<DateTime>(sleepStart);
    map['total_sleep_minutes'] = Variable<int>(totalSleepMinutes);
    if (!nullToAbsent || efficiency != null) {
      map['efficiency'] = Variable<double>(efficiency);
    }
    return map;
  }

  ManualSleepRecordsCompanion toCompanion(bool nullToAbsent) {
    return ManualSleepRecordsCompanion(
      night: Value(night),
      sleepStart: Value(sleepStart),
      totalSleepMinutes: Value(totalSleepMinutes),
      efficiency: efficiency == null && nullToAbsent
          ? const Value.absent()
          : Value(efficiency),
    );
  }

  factory ManualSleepRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManualSleepRecord(
      night: serializer.fromJson<DateTime>(json['night']),
      sleepStart: serializer.fromJson<DateTime>(json['sleepStart']),
      totalSleepMinutes: serializer.fromJson<int>(json['totalSleepMinutes']),
      efficiency: serializer.fromJson<double?>(json['efficiency']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'night': serializer.toJson<DateTime>(night),
      'sleepStart': serializer.toJson<DateTime>(sleepStart),
      'totalSleepMinutes': serializer.toJson<int>(totalSleepMinutes),
      'efficiency': serializer.toJson<double?>(efficiency),
    };
  }

  ManualSleepRecord copyWith({
    DateTime? night,
    DateTime? sleepStart,
    int? totalSleepMinutes,
    Value<double?> efficiency = const Value.absent(),
  }) => ManualSleepRecord(
    night: night ?? this.night,
    sleepStart: sleepStart ?? this.sleepStart,
    totalSleepMinutes: totalSleepMinutes ?? this.totalSleepMinutes,
    efficiency: efficiency.present ? efficiency.value : this.efficiency,
  );
  ManualSleepRecord copyWithCompanion(ManualSleepRecordsCompanion data) {
    return ManualSleepRecord(
      night: data.night.present ? data.night.value : this.night,
      sleepStart: data.sleepStart.present
          ? data.sleepStart.value
          : this.sleepStart,
      totalSleepMinutes: data.totalSleepMinutes.present
          ? data.totalSleepMinutes.value
          : this.totalSleepMinutes,
      efficiency: data.efficiency.present
          ? data.efficiency.value
          : this.efficiency,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManualSleepRecord(')
          ..write('night: $night, ')
          ..write('sleepStart: $sleepStart, ')
          ..write('totalSleepMinutes: $totalSleepMinutes, ')
          ..write('efficiency: $efficiency')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(night, sleepStart, totalSleepMinutes, efficiency);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManualSleepRecord &&
          other.night == this.night &&
          other.sleepStart == this.sleepStart &&
          other.totalSleepMinutes == this.totalSleepMinutes &&
          other.efficiency == this.efficiency);
}

class ManualSleepRecordsCompanion extends UpdateCompanion<ManualSleepRecord> {
  final Value<DateTime> night;
  final Value<DateTime> sleepStart;
  final Value<int> totalSleepMinutes;
  final Value<double?> efficiency;
  final Value<int> rowid;
  const ManualSleepRecordsCompanion({
    this.night = const Value.absent(),
    this.sleepStart = const Value.absent(),
    this.totalSleepMinutes = const Value.absent(),
    this.efficiency = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManualSleepRecordsCompanion.insert({
    required DateTime night,
    required DateTime sleepStart,
    required int totalSleepMinutes,
    this.efficiency = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : night = Value(night),
       sleepStart = Value(sleepStart),
       totalSleepMinutes = Value(totalSleepMinutes);
  static Insertable<ManualSleepRecord> custom({
    Expression<DateTime>? night,
    Expression<DateTime>? sleepStart,
    Expression<int>? totalSleepMinutes,
    Expression<double>? efficiency,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (night != null) 'night': night,
      if (sleepStart != null) 'sleep_start': sleepStart,
      if (totalSleepMinutes != null) 'total_sleep_minutes': totalSleepMinutes,
      if (efficiency != null) 'efficiency': efficiency,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManualSleepRecordsCompanion copyWith({
    Value<DateTime>? night,
    Value<DateTime>? sleepStart,
    Value<int>? totalSleepMinutes,
    Value<double?>? efficiency,
    Value<int>? rowid,
  }) {
    return ManualSleepRecordsCompanion(
      night: night ?? this.night,
      sleepStart: sleepStart ?? this.sleepStart,
      totalSleepMinutes: totalSleepMinutes ?? this.totalSleepMinutes,
      efficiency: efficiency ?? this.efficiency,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (night.present) {
      map['night'] = Variable<DateTime>(night.value);
    }
    if (sleepStart.present) {
      map['sleep_start'] = Variable<DateTime>(sleepStart.value);
    }
    if (totalSleepMinutes.present) {
      map['total_sleep_minutes'] = Variable<int>(totalSleepMinutes.value);
    }
    if (efficiency.present) {
      map['efficiency'] = Variable<double>(efficiency.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManualSleepRecordsCompanion(')
          ..write('night: $night, ')
          ..write('sleepStart: $sleepStart, ')
          ..write('totalSleepMinutes: $totalSleepMinutes, ')
          ..write('efficiency: $efficiency, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayLocationOverridesTable extends DayLocationOverrides
    with TableInfo<$DayLocationOverridesTable, DayLocationOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayLocationOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setAtMeta = const VerificationMeta('setAt');
  @override
  late final GeneratedColumn<DateTime> setAt = GeneratedColumn<DateTime>(
    'set_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day, lat, lon, displayName, setAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_location_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayLocationOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('set_at')) {
      context.handle(
        _setAtMeta,
        setAt.isAcceptableOrUnknown(data['set_at']!, _setAtMeta),
      );
    } else if (isInserting) {
      context.missing(_setAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  DayLocationOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayLocationOverride(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      setAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}set_at'],
      )!,
    );
  }

  @override
  $DayLocationOverridesTable createAlias(String alias) {
    return $DayLocationOverridesTable(attachedDatabase, alias);
  }
}

class DayLocationOverride extends DataClass
    implements Insertable<DayLocationOverride> {
  /// UTC midnight of the calendar day this override applies to.
  final DateTime day;
  final double lat;
  final double lon;
  final String displayName;

  /// When the override was set — for audit and future "revert" capability.
  final DateTime setAt;
  const DayLocationOverride({
    required this.day,
    required this.lat,
    required this.lon,
    required this.displayName,
    required this.setAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<DateTime>(day);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['display_name'] = Variable<String>(displayName);
    map['set_at'] = Variable<DateTime>(setAt);
    return map;
  }

  DayLocationOverridesCompanion toCompanion(bool nullToAbsent) {
    return DayLocationOverridesCompanion(
      day: Value(day),
      lat: Value(lat),
      lon: Value(lon),
      displayName: Value(displayName),
      setAt: Value(setAt),
    );
  }

  factory DayLocationOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayLocationOverride(
      day: serializer.fromJson<DateTime>(json['day']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      displayName: serializer.fromJson<String>(json['displayName']),
      setAt: serializer.fromJson<DateTime>(json['setAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<DateTime>(day),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'displayName': serializer.toJson<String>(displayName),
      'setAt': serializer.toJson<DateTime>(setAt),
    };
  }

  DayLocationOverride copyWith({
    DateTime? day,
    double? lat,
    double? lon,
    String? displayName,
    DateTime? setAt,
  }) => DayLocationOverride(
    day: day ?? this.day,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    displayName: displayName ?? this.displayName,
    setAt: setAt ?? this.setAt,
  );
  DayLocationOverride copyWithCompanion(DayLocationOverridesCompanion data) {
    return DayLocationOverride(
      day: data.day.present ? data.day.value : this.day,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      setAt: data.setAt.present ? data.setAt.value : this.setAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayLocationOverride(')
          ..write('day: $day, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('displayName: $displayName, ')
          ..write('setAt: $setAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, lat, lon, displayName, setAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayLocationOverride &&
          other.day == this.day &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.displayName == this.displayName &&
          other.setAt == this.setAt);
}

class DayLocationOverridesCompanion
    extends UpdateCompanion<DayLocationOverride> {
  final Value<DateTime> day;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String> displayName;
  final Value<DateTime> setAt;
  final Value<int> rowid;
  const DayLocationOverridesCompanion({
    this.day = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.displayName = const Value.absent(),
    this.setAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayLocationOverridesCompanion.insert({
    required DateTime day,
    required double lat,
    required double lon,
    required String displayName,
    required DateTime setAt,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       lat = Value(lat),
       lon = Value(lon),
       displayName = Value(displayName),
       setAt = Value(setAt);
  static Insertable<DayLocationOverride> custom({
    Expression<DateTime>? day,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? displayName,
    Expression<DateTime>? setAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (displayName != null) 'display_name': displayName,
      if (setAt != null) 'set_at': setAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayLocationOverridesCompanion copyWith({
    Value<DateTime>? day,
    Value<double>? lat,
    Value<double>? lon,
    Value<String>? displayName,
    Value<DateTime>? setAt,
    Value<int>? rowid,
  }) {
    return DayLocationOverridesCompanion(
      day: day ?? this.day,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      displayName: displayName ?? this.displayName,
      setAt: setAt ?? this.setAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (setAt.present) {
      map['set_at'] = Variable<DateTime>(setAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayLocationOverridesCompanion(')
          ..write('day: $day, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('displayName: $displayName, ')
          ..write('setAt: $setAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OuraSleepTable extends OuraSleep
    with TableInfo<$OuraSleepTable, OuraSleepData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OuraSleepTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lowestHeartRateMeta = const VerificationMeta(
    'lowestHeartRate',
  );
  @override
  late final GeneratedColumn<int> lowestHeartRate = GeneratedColumn<int>(
    'lowest_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restlessPeriodsMeta = const VerificationMeta(
    'restlessPeriods',
  );
  @override
  late final GeneratedColumn<int> restlessPeriods = GeneratedColumn<int>(
    'restless_periods',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _averageHeartRateMeta = const VerificationMeta(
    'averageHeartRate',
  );
  @override
  late final GeneratedColumn<double> averageHeartRate = GeneratedColumn<double>(
    'average_heart_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _averageHrvMeta = const VerificationMeta(
    'averageHrv',
  );
  @override
  late final GeneratedColumn<int> averageHrv = GeneratedColumn<int>(
    'average_hrv',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    day,
    lowestHeartRate,
    restlessPeriods,
    averageHeartRate,
    averageHrv,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oura_sleep';
  @override
  VerificationContext validateIntegrity(
    Insertable<OuraSleepData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('lowest_heart_rate')) {
      context.handle(
        _lowestHeartRateMeta,
        lowestHeartRate.isAcceptableOrUnknown(
          data['lowest_heart_rate']!,
          _lowestHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('restless_periods')) {
      context.handle(
        _restlessPeriodsMeta,
        restlessPeriods.isAcceptableOrUnknown(
          data['restless_periods']!,
          _restlessPeriodsMeta,
        ),
      );
    }
    if (data.containsKey('average_heart_rate')) {
      context.handle(
        _averageHeartRateMeta,
        averageHeartRate.isAcceptableOrUnknown(
          data['average_heart_rate']!,
          _averageHeartRateMeta,
        ),
      );
    }
    if (data.containsKey('average_hrv')) {
      context.handle(
        _averageHrvMeta,
        averageHrv.isAcceptableOrUnknown(data['average_hrv']!, _averageHrvMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OuraSleepData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OuraSleepData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      lowestHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lowest_heart_rate'],
      ),
      restlessPeriods: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}restless_periods'],
      ),
      averageHeartRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_heart_rate'],
      ),
      averageHrv: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}average_hrv'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $OuraSleepTable createAlias(String alias) {
    return $OuraSleepTable(attachedDatabase, alias);
  }
}

class OuraSleepData extends DataClass implements Insertable<OuraSleepData> {
  final String id;
  final DateTime day;
  final int? lowestHeartRate;
  final int? restlessPeriods;
  final double? averageHeartRate;
  final int? averageHrv;
  final DateTime fetchedAt;
  const OuraSleepData({
    required this.id,
    required this.day,
    this.lowestHeartRate,
    this.restlessPeriods,
    this.averageHeartRate,
    this.averageHrv,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<DateTime>(day);
    if (!nullToAbsent || lowestHeartRate != null) {
      map['lowest_heart_rate'] = Variable<int>(lowestHeartRate);
    }
    if (!nullToAbsent || restlessPeriods != null) {
      map['restless_periods'] = Variable<int>(restlessPeriods);
    }
    if (!nullToAbsent || averageHeartRate != null) {
      map['average_heart_rate'] = Variable<double>(averageHeartRate);
    }
    if (!nullToAbsent || averageHrv != null) {
      map['average_hrv'] = Variable<int>(averageHrv);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  OuraSleepCompanion toCompanion(bool nullToAbsent) {
    return OuraSleepCompanion(
      id: Value(id),
      day: Value(day),
      lowestHeartRate: lowestHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(lowestHeartRate),
      restlessPeriods: restlessPeriods == null && nullToAbsent
          ? const Value.absent()
          : Value(restlessPeriods),
      averageHeartRate: averageHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(averageHeartRate),
      averageHrv: averageHrv == null && nullToAbsent
          ? const Value.absent()
          : Value(averageHrv),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory OuraSleepData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OuraSleepData(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<DateTime>(json['day']),
      lowestHeartRate: serializer.fromJson<int?>(json['lowestHeartRate']),
      restlessPeriods: serializer.fromJson<int?>(json['restlessPeriods']),
      averageHeartRate: serializer.fromJson<double?>(json['averageHeartRate']),
      averageHrv: serializer.fromJson<int?>(json['averageHrv']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<DateTime>(day),
      'lowestHeartRate': serializer.toJson<int?>(lowestHeartRate),
      'restlessPeriods': serializer.toJson<int?>(restlessPeriods),
      'averageHeartRate': serializer.toJson<double?>(averageHeartRate),
      'averageHrv': serializer.toJson<int?>(averageHrv),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  OuraSleepData copyWith({
    String? id,
    DateTime? day,
    Value<int?> lowestHeartRate = const Value.absent(),
    Value<int?> restlessPeriods = const Value.absent(),
    Value<double?> averageHeartRate = const Value.absent(),
    Value<int?> averageHrv = const Value.absent(),
    DateTime? fetchedAt,
  }) => OuraSleepData(
    id: id ?? this.id,
    day: day ?? this.day,
    lowestHeartRate: lowestHeartRate.present
        ? lowestHeartRate.value
        : this.lowestHeartRate,
    restlessPeriods: restlessPeriods.present
        ? restlessPeriods.value
        : this.restlessPeriods,
    averageHeartRate: averageHeartRate.present
        ? averageHeartRate.value
        : this.averageHeartRate,
    averageHrv: averageHrv.present ? averageHrv.value : this.averageHrv,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  OuraSleepData copyWithCompanion(OuraSleepCompanion data) {
    return OuraSleepData(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      lowestHeartRate: data.lowestHeartRate.present
          ? data.lowestHeartRate.value
          : this.lowestHeartRate,
      restlessPeriods: data.restlessPeriods.present
          ? data.restlessPeriods.value
          : this.restlessPeriods,
      averageHeartRate: data.averageHeartRate.present
          ? data.averageHeartRate.value
          : this.averageHeartRate,
      averageHrv: data.averageHrv.present
          ? data.averageHrv.value
          : this.averageHrv,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OuraSleepData(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('lowestHeartRate: $lowestHeartRate, ')
          ..write('restlessPeriods: $restlessPeriods, ')
          ..write('averageHeartRate: $averageHeartRate, ')
          ..write('averageHrv: $averageHrv, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    day,
    lowestHeartRate,
    restlessPeriods,
    averageHeartRate,
    averageHrv,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OuraSleepData &&
          other.id == this.id &&
          other.day == this.day &&
          other.lowestHeartRate == this.lowestHeartRate &&
          other.restlessPeriods == this.restlessPeriods &&
          other.averageHeartRate == this.averageHeartRate &&
          other.averageHrv == this.averageHrv &&
          other.fetchedAt == this.fetchedAt);
}

class OuraSleepCompanion extends UpdateCompanion<OuraSleepData> {
  final Value<String> id;
  final Value<DateTime> day;
  final Value<int?> lowestHeartRate;
  final Value<int?> restlessPeriods;
  final Value<double?> averageHeartRate;
  final Value<int?> averageHrv;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const OuraSleepCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.lowestHeartRate = const Value.absent(),
    this.restlessPeriods = const Value.absent(),
    this.averageHeartRate = const Value.absent(),
    this.averageHrv = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OuraSleepCompanion.insert({
    required String id,
    required DateTime day,
    this.lowestHeartRate = const Value.absent(),
    this.restlessPeriods = const Value.absent(),
    this.averageHeartRate = const Value.absent(),
    this.averageHrv = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       fetchedAt = Value(fetchedAt);
  static Insertable<OuraSleepData> custom({
    Expression<String>? id,
    Expression<DateTime>? day,
    Expression<int>? lowestHeartRate,
    Expression<int>? restlessPeriods,
    Expression<double>? averageHeartRate,
    Expression<int>? averageHrv,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (lowestHeartRate != null) 'lowest_heart_rate': lowestHeartRate,
      if (restlessPeriods != null) 'restless_periods': restlessPeriods,
      if (averageHeartRate != null) 'average_heart_rate': averageHeartRate,
      if (averageHrv != null) 'average_hrv': averageHrv,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OuraSleepCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? day,
    Value<int?>? lowestHeartRate,
    Value<int?>? restlessPeriods,
    Value<double?>? averageHeartRate,
    Value<int?>? averageHrv,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return OuraSleepCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      lowestHeartRate: lowestHeartRate ?? this.lowestHeartRate,
      restlessPeriods: restlessPeriods ?? this.restlessPeriods,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      averageHrv: averageHrv ?? this.averageHrv,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (lowestHeartRate.present) {
      map['lowest_heart_rate'] = Variable<int>(lowestHeartRate.value);
    }
    if (restlessPeriods.present) {
      map['restless_periods'] = Variable<int>(restlessPeriods.value);
    }
    if (averageHeartRate.present) {
      map['average_heart_rate'] = Variable<double>(averageHeartRate.value);
    }
    if (averageHrv.present) {
      map['average_hrv'] = Variable<int>(averageHrv.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OuraSleepCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('lowestHeartRate: $lowestHeartRate, ')
          ..write('restlessPeriods: $restlessPeriods, ')
          ..write('averageHeartRate: $averageHeartRate, ')
          ..write('averageHrv: $averageHrv, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OuraDailySleepTable extends OuraDailySleep
    with TableInfo<$OuraDailySleepTable, OuraDailySleepData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OuraDailySleepTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, day, score, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oura_daily_sleep';
  @override
  VerificationContext validateIntegrity(
    Insertable<OuraDailySleepData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OuraDailySleepData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OuraDailySleepData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $OuraDailySleepTable createAlias(String alias) {
    return $OuraDailySleepTable(attachedDatabase, alias);
  }
}

class OuraDailySleepData extends DataClass
    implements Insertable<OuraDailySleepData> {
  final String id;
  final DateTime day;
  final int? score;
  final DateTime fetchedAt;
  const OuraDailySleepData({
    required this.id,
    required this.day,
    this.score,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<DateTime>(day);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  OuraDailySleepCompanion toCompanion(bool nullToAbsent) {
    return OuraDailySleepCompanion(
      id: Value(id),
      day: Value(day),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory OuraDailySleepData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OuraDailySleepData(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<DateTime>(json['day']),
      score: serializer.fromJson<int?>(json['score']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<DateTime>(day),
      'score': serializer.toJson<int?>(score),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  OuraDailySleepData copyWith({
    String? id,
    DateTime? day,
    Value<int?> score = const Value.absent(),
    DateTime? fetchedAt,
  }) => OuraDailySleepData(
    id: id ?? this.id,
    day: day ?? this.day,
    score: score.present ? score.value : this.score,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  OuraDailySleepData copyWithCompanion(OuraDailySleepCompanion data) {
    return OuraDailySleepData(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      score: data.score.present ? data.score.value : this.score,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OuraDailySleepData(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('score: $score, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, score, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OuraDailySleepData &&
          other.id == this.id &&
          other.day == this.day &&
          other.score == this.score &&
          other.fetchedAt == this.fetchedAt);
}

class OuraDailySleepCompanion extends UpdateCompanion<OuraDailySleepData> {
  final Value<String> id;
  final Value<DateTime> day;
  final Value<int?> score;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const OuraDailySleepCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.score = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OuraDailySleepCompanion.insert({
    required String id,
    required DateTime day,
    this.score = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       fetchedAt = Value(fetchedAt);
  static Insertable<OuraDailySleepData> custom({
    Expression<String>? id,
    Expression<DateTime>? day,
    Expression<int>? score,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (score != null) 'score': score,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OuraDailySleepCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? day,
    Value<int?>? score,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return OuraDailySleepCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      score: score ?? this.score,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OuraDailySleepCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('score: $score, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OuraActivityTable extends OuraActivity
    with TableInfo<$OuraActivityTable, OuraActivityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OuraActivityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityScoreMeta = const VerificationMeta(
    'activityScore',
  );
  @override
  late final GeneratedColumn<int> activityScore = GeneratedColumn<int>(
    'activity_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, day, activityScore, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oura_activity';
  @override
  VerificationContext validateIntegrity(
    Insertable<OuraActivityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('activity_score')) {
      context.handle(
        _activityScoreMeta,
        activityScore.isAcceptableOrUnknown(
          data['activity_score']!,
          _activityScoreMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OuraActivityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OuraActivityData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      activityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_score'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $OuraActivityTable createAlias(String alias) {
    return $OuraActivityTable(attachedDatabase, alias);
  }
}

class OuraActivityData extends DataClass
    implements Insertable<OuraActivityData> {
  final String id;
  final DateTime day;
  final int? activityScore;
  final DateTime fetchedAt;
  const OuraActivityData({
    required this.id,
    required this.day,
    this.activityScore,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<DateTime>(day);
    if (!nullToAbsent || activityScore != null) {
      map['activity_score'] = Variable<int>(activityScore);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  OuraActivityCompanion toCompanion(bool nullToAbsent) {
    return OuraActivityCompanion(
      id: Value(id),
      day: Value(day),
      activityScore: activityScore == null && nullToAbsent
          ? const Value.absent()
          : Value(activityScore),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory OuraActivityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OuraActivityData(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<DateTime>(json['day']),
      activityScore: serializer.fromJson<int?>(json['activityScore']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<DateTime>(day),
      'activityScore': serializer.toJson<int?>(activityScore),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  OuraActivityData copyWith({
    String? id,
    DateTime? day,
    Value<int?> activityScore = const Value.absent(),
    DateTime? fetchedAt,
  }) => OuraActivityData(
    id: id ?? this.id,
    day: day ?? this.day,
    activityScore: activityScore.present
        ? activityScore.value
        : this.activityScore,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  OuraActivityData copyWithCompanion(OuraActivityCompanion data) {
    return OuraActivityData(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      activityScore: data.activityScore.present
          ? data.activityScore.value
          : this.activityScore,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OuraActivityData(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('activityScore: $activityScore, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, activityScore, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OuraActivityData &&
          other.id == this.id &&
          other.day == this.day &&
          other.activityScore == this.activityScore &&
          other.fetchedAt == this.fetchedAt);
}

class OuraActivityCompanion extends UpdateCompanion<OuraActivityData> {
  final Value<String> id;
  final Value<DateTime> day;
  final Value<int?> activityScore;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const OuraActivityCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.activityScore = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OuraActivityCompanion.insert({
    required String id,
    required DateTime day,
    this.activityScore = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       fetchedAt = Value(fetchedAt);
  static Insertable<OuraActivityData> custom({
    Expression<String>? id,
    Expression<DateTime>? day,
    Expression<int>? activityScore,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (activityScore != null) 'activity_score': activityScore,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OuraActivityCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? day,
    Value<int?>? activityScore,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return OuraActivityCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      activityScore: activityScore ?? this.activityScore,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (activityScore.present) {
      map['activity_score'] = Variable<int>(activityScore.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OuraActivityCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('activityScore: $activityScore, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OuraReadinessTable extends OuraReadiness
    with TableInfo<$OuraReadinessTable, OuraReadinessData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OuraReadinessTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readinessScoreMeta = const VerificationMeta(
    'readinessScore',
  );
  @override
  late final GeneratedColumn<int> readinessScore = GeneratedColumn<int>(
    'readiness_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureDeviationMeta =
      const VerificationMeta('temperatureDeviation');
  @override
  late final GeneratedColumn<double> temperatureDeviation =
      GeneratedColumn<double>(
        'temperature_deviation',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    day,
    readinessScore,
    temperatureDeviation,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oura_readiness';
  @override
  VerificationContext validateIntegrity(
    Insertable<OuraReadinessData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('readiness_score')) {
      context.handle(
        _readinessScoreMeta,
        readinessScore.isAcceptableOrUnknown(
          data['readiness_score']!,
          _readinessScoreMeta,
        ),
      );
    }
    if (data.containsKey('temperature_deviation')) {
      context.handle(
        _temperatureDeviationMeta,
        temperatureDeviation.isAcceptableOrUnknown(
          data['temperature_deviation']!,
          _temperatureDeviationMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OuraReadinessData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OuraReadinessData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      readinessScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}readiness_score'],
      ),
      temperatureDeviation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_deviation'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $OuraReadinessTable createAlias(String alias) {
    return $OuraReadinessTable(attachedDatabase, alias);
  }
}

class OuraReadinessData extends DataClass
    implements Insertable<OuraReadinessData> {
  final String id;
  final DateTime day;
  final int? readinessScore;
  final double? temperatureDeviation;
  final DateTime fetchedAt;
  const OuraReadinessData({
    required this.id,
    required this.day,
    this.readinessScore,
    this.temperatureDeviation,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<DateTime>(day);
    if (!nullToAbsent || readinessScore != null) {
      map['readiness_score'] = Variable<int>(readinessScore);
    }
    if (!nullToAbsent || temperatureDeviation != null) {
      map['temperature_deviation'] = Variable<double>(temperatureDeviation);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  OuraReadinessCompanion toCompanion(bool nullToAbsent) {
    return OuraReadinessCompanion(
      id: Value(id),
      day: Value(day),
      readinessScore: readinessScore == null && nullToAbsent
          ? const Value.absent()
          : Value(readinessScore),
      temperatureDeviation: temperatureDeviation == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureDeviation),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory OuraReadinessData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OuraReadinessData(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<DateTime>(json['day']),
      readinessScore: serializer.fromJson<int?>(json['readinessScore']),
      temperatureDeviation: serializer.fromJson<double?>(
        json['temperatureDeviation'],
      ),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<DateTime>(day),
      'readinessScore': serializer.toJson<int?>(readinessScore),
      'temperatureDeviation': serializer.toJson<double?>(temperatureDeviation),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  OuraReadinessData copyWith({
    String? id,
    DateTime? day,
    Value<int?> readinessScore = const Value.absent(),
    Value<double?> temperatureDeviation = const Value.absent(),
    DateTime? fetchedAt,
  }) => OuraReadinessData(
    id: id ?? this.id,
    day: day ?? this.day,
    readinessScore: readinessScore.present
        ? readinessScore.value
        : this.readinessScore,
    temperatureDeviation: temperatureDeviation.present
        ? temperatureDeviation.value
        : this.temperatureDeviation,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  OuraReadinessData copyWithCompanion(OuraReadinessCompanion data) {
    return OuraReadinessData(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      readinessScore: data.readinessScore.present
          ? data.readinessScore.value
          : this.readinessScore,
      temperatureDeviation: data.temperatureDeviation.present
          ? data.temperatureDeviation.value
          : this.temperatureDeviation,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OuraReadinessData(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('readinessScore: $readinessScore, ')
          ..write('temperatureDeviation: $temperatureDeviation, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, day, readinessScore, temperatureDeviation, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OuraReadinessData &&
          other.id == this.id &&
          other.day == this.day &&
          other.readinessScore == this.readinessScore &&
          other.temperatureDeviation == this.temperatureDeviation &&
          other.fetchedAt == this.fetchedAt);
}

class OuraReadinessCompanion extends UpdateCompanion<OuraReadinessData> {
  final Value<String> id;
  final Value<DateTime> day;
  final Value<int?> readinessScore;
  final Value<double?> temperatureDeviation;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const OuraReadinessCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.readinessScore = const Value.absent(),
    this.temperatureDeviation = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OuraReadinessCompanion.insert({
    required String id,
    required DateTime day,
    this.readinessScore = const Value.absent(),
    this.temperatureDeviation = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       fetchedAt = Value(fetchedAt);
  static Insertable<OuraReadinessData> custom({
    Expression<String>? id,
    Expression<DateTime>? day,
    Expression<int>? readinessScore,
    Expression<double>? temperatureDeviation,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (readinessScore != null) 'readiness_score': readinessScore,
      if (temperatureDeviation != null)
        'temperature_deviation': temperatureDeviation,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OuraReadinessCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? day,
    Value<int?>? readinessScore,
    Value<double?>? temperatureDeviation,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return OuraReadinessCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      readinessScore: readinessScore ?? this.readinessScore,
      temperatureDeviation: temperatureDeviation ?? this.temperatureDeviation,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (readinessScore.present) {
      map['readiness_score'] = Variable<int>(readinessScore.value);
    }
    if (temperatureDeviation.present) {
      map['temperature_deviation'] = Variable<double>(
        temperatureDeviation.value,
      );
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OuraReadinessCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('readinessScore: $readinessScore, ')
          ..write('temperatureDeviation: $temperatureDeviation, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AttacksTable attacks = $AttacksTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $WeatherSnapshotsTable weatherSnapshots = $WeatherSnapshotsTable(
    this,
  );
  late final $BaselinesKvTable baselinesKv = $BaselinesKvTable(this);
  late final $UserTriggerFlagsTblTable userTriggerFlagsTbl =
      $UserTriggerFlagsTblTable(this);
  late final $RiskAssessmentsTable riskAssessments = $RiskAssessmentsTable(
    this,
  );
  late final $SettingsTable settings = $SettingsTable(this);
  late final $NotificationsSentTable notificationsSent =
      $NotificationsSentTable(this);
  late final $PeriodsTable periods = $PeriodsTable(this);
  late final $PeriodDaySeveritiesTable periodDaySeverities =
      $PeriodDaySeveritiesTable(this);
  late final $ManualSleepRecordsTable manualSleepRecords =
      $ManualSleepRecordsTable(this);
  late final $DayLocationOverridesTable dayLocationOverrides =
      $DayLocationOverridesTable(this);
  late final $OuraSleepTable ouraSleep = $OuraSleepTable(this);
  late final $OuraDailySleepTable ouraDailySleep = $OuraDailySleepTable(this);
  late final $OuraActivityTable ouraActivity = $OuraActivityTable(this);
  late final $OuraReadinessTable ouraReadiness = $OuraReadinessTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    attacks,
    journalEntries,
    weatherSnapshots,
    baselinesKv,
    userTriggerFlagsTbl,
    riskAssessments,
    settings,
    notificationsSent,
    periods,
    periodDaySeverities,
    manualSleepRecords,
    dayLocationOverrides,
    ouraSleep,
    ouraDailySleep,
    ouraActivity,
    ouraReadiness,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$AttacksTableCreateCompanionBuilder =
    AttacksCompanion Function({
      Value<int> id,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required int severity,
      Value<String?> notes,
      Value<int?> riskAssessmentId,
      Value<bool> inProgress,
    });
typedef $$AttacksTableUpdateCompanionBuilder =
    AttacksCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> severity,
      Value<String?> notes,
      Value<int?> riskAssessmentId,
      Value<bool> inProgress,
    });

class $$AttacksTableFilterComposer
    extends Composer<_$AppDatabase, $AttacksTable> {
  $$AttacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get riskAssessmentId => $composableBuilder(
    column: $table.riskAssessmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inProgress => $composableBuilder(
    column: $table.inProgress,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttacksTableOrderingComposer
    extends Composer<_$AppDatabase, $AttacksTable> {
  $$AttacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get riskAssessmentId => $composableBuilder(
    column: $table.riskAssessmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inProgress => $composableBuilder(
    column: $table.inProgress,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttacksTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttacksTable> {
  $$AttacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get riskAssessmentId => $composableBuilder(
    column: $table.riskAssessmentId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get inProgress => $composableBuilder(
    column: $table.inProgress,
    builder: (column) => column,
  );
}

class $$AttacksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttacksTable,
          Attack,
          $$AttacksTableFilterComposer,
          $$AttacksTableOrderingComposer,
          $$AttacksTableAnnotationComposer,
          $$AttacksTableCreateCompanionBuilder,
          $$AttacksTableUpdateCompanionBuilder,
          (Attack, BaseReferences<_$AppDatabase, $AttacksTable, Attack>),
          Attack,
          PrefetchHooks Function()
        > {
  $$AttacksTableTableManager(_$AppDatabase db, $AttacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> severity = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> riskAssessmentId = const Value.absent(),
                Value<bool> inProgress = const Value.absent(),
              }) => AttacksCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                severity: severity,
                notes: notes,
                riskAssessmentId: riskAssessmentId,
                inProgress: inProgress,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required int severity,
                Value<String?> notes = const Value.absent(),
                Value<int?> riskAssessmentId = const Value.absent(),
                Value<bool> inProgress = const Value.absent(),
              }) => AttacksCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                severity: severity,
                notes: notes,
                riskAssessmentId: riskAssessmentId,
                inProgress: inProgress,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttacksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttacksTable,
      Attack,
      $$AttacksTableFilterComposer,
      $$AttacksTableOrderingComposer,
      $$AttacksTableAnnotationComposer,
      $$AttacksTableCreateCompanionBuilder,
      $$AttacksTableUpdateCompanionBuilder,
      (Attack, BaseReferences<_$AppDatabase, $AttacksTable, Attack>),
      Attack,
      PrefetchHooks Function()
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      required DateTime at,
      required String kind,
      required String payloadJson,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> at,
      Value<String> kind,
      Value<String> payloadJson,
    });

class $$JournalEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalEntriesTable,
          JournalEntry,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (
            JournalEntry,
            BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntry>,
          ),
          JournalEntry,
          PrefetchHooks Function()
        > {
  $$JournalEntriesTableTableManager(
    _$AppDatabase db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
              }) => JournalEntriesCompanion(
                id: id,
                at: at,
                kind: kind,
                payloadJson: payloadJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String kind,
                required String payloadJson,
              }) => JournalEntriesCompanion.insert(
                id: id,
                at: at,
                kind: kind,
                payloadJson: payloadJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalEntriesTable,
      JournalEntry,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (
        JournalEntry,
        BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntry>,
      ),
      JournalEntry,
      PrefetchHooks Function()
    >;
typedef $$WeatherSnapshotsTableCreateCompanionBuilder =
    WeatherSnapshotsCompanion Function({
      Value<int> id,
      required DateTime fetchedAt,
      required double lat,
      required double lon,
      required String forecastJson,
      Value<String?> airQualityJson,
      Value<String> source,
      Value<DateTime?> coverageStart,
      Value<DateTime?> coverageEnd,
    });
typedef $$WeatherSnapshotsTableUpdateCompanionBuilder =
    WeatherSnapshotsCompanion Function({
      Value<int> id,
      Value<DateTime> fetchedAt,
      Value<double> lat,
      Value<double> lon,
      Value<String> forecastJson,
      Value<String?> airQualityJson,
      Value<String> source,
      Value<DateTime?> coverageStart,
      Value<DateTime?> coverageEnd,
    });

class $$WeatherSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherSnapshotsTable> {
  $$WeatherSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forecastJson => $composableBuilder(
    column: $table.forecastJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get airQualityJson => $composableBuilder(
    column: $table.airQualityJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get coverageStart => $composableBuilder(
    column: $table.coverageStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get coverageEnd => $composableBuilder(
    column: $table.coverageEnd,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeatherSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherSnapshotsTable> {
  $$WeatherSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forecastJson => $composableBuilder(
    column: $table.forecastJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get airQualityJson => $composableBuilder(
    column: $table.airQualityJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get coverageStart => $composableBuilder(
    column: $table.coverageStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get coverageEnd => $composableBuilder(
    column: $table.coverageEnd,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeatherSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherSnapshotsTable> {
  $$WeatherSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get forecastJson => $composableBuilder(
    column: $table.forecastJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get airQualityJson => $composableBuilder(
    column: $table.airQualityJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get coverageStart => $composableBuilder(
    column: $table.coverageStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get coverageEnd => $composableBuilder(
    column: $table.coverageEnd,
    builder: (column) => column,
  );
}

class $$WeatherSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherSnapshotsTable,
          WeatherSnapshot,
          $$WeatherSnapshotsTableFilterComposer,
          $$WeatherSnapshotsTableOrderingComposer,
          $$WeatherSnapshotsTableAnnotationComposer,
          $$WeatherSnapshotsTableCreateCompanionBuilder,
          $$WeatherSnapshotsTableUpdateCompanionBuilder,
          (
            WeatherSnapshot,
            BaseReferences<
              _$AppDatabase,
              $WeatherSnapshotsTable,
              WeatherSnapshot
            >,
          ),
          WeatherSnapshot,
          PrefetchHooks Function()
        > {
  $$WeatherSnapshotsTableTableManager(
    _$AppDatabase db,
    $WeatherSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeatherSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeatherSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<String> forecastJson = const Value.absent(),
                Value<String?> airQualityJson = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> coverageStart = const Value.absent(),
                Value<DateTime?> coverageEnd = const Value.absent(),
              }) => WeatherSnapshotsCompanion(
                id: id,
                fetchedAt: fetchedAt,
                lat: lat,
                lon: lon,
                forecastJson: forecastJson,
                airQualityJson: airQualityJson,
                source: source,
                coverageStart: coverageStart,
                coverageEnd: coverageEnd,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime fetchedAt,
                required double lat,
                required double lon,
                required String forecastJson,
                Value<String?> airQualityJson = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> coverageStart = const Value.absent(),
                Value<DateTime?> coverageEnd = const Value.absent(),
              }) => WeatherSnapshotsCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                lat: lat,
                lon: lon,
                forecastJson: forecastJson,
                airQualityJson: airQualityJson,
                source: source,
                coverageStart: coverageStart,
                coverageEnd: coverageEnd,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeatherSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherSnapshotsTable,
      WeatherSnapshot,
      $$WeatherSnapshotsTableFilterComposer,
      $$WeatherSnapshotsTableOrderingComposer,
      $$WeatherSnapshotsTableAnnotationComposer,
      $$WeatherSnapshotsTableCreateCompanionBuilder,
      $$WeatherSnapshotsTableUpdateCompanionBuilder,
      (
        WeatherSnapshot,
        BaseReferences<_$AppDatabase, $WeatherSnapshotsTable, WeatherSnapshot>,
      ),
      WeatherSnapshot,
      PrefetchHooks Function()
    >;
typedef $$BaselinesKvTableCreateCompanionBuilder =
    BaselinesKvCompanion Function({
      required String key,
      required double value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BaselinesKvTableUpdateCompanionBuilder =
    BaselinesKvCompanion Function({
      Value<String> key,
      Value<double> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BaselinesKvTableFilterComposer
    extends Composer<_$AppDatabase, $BaselinesKvTable> {
  $$BaselinesKvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BaselinesKvTableOrderingComposer
    extends Composer<_$AppDatabase, $BaselinesKvTable> {
  $$BaselinesKvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BaselinesKvTableAnnotationComposer
    extends Composer<_$AppDatabase, $BaselinesKvTable> {
  $$BaselinesKvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BaselinesKvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BaselinesKvTable,
          BaselinesKvData,
          $$BaselinesKvTableFilterComposer,
          $$BaselinesKvTableOrderingComposer,
          $$BaselinesKvTableAnnotationComposer,
          $$BaselinesKvTableCreateCompanionBuilder,
          $$BaselinesKvTableUpdateCompanionBuilder,
          (
            BaselinesKvData,
            BaseReferences<_$AppDatabase, $BaselinesKvTable, BaselinesKvData>,
          ),
          BaselinesKvData,
          PrefetchHooks Function()
        > {
  $$BaselinesKvTableTableManager(_$AppDatabase db, $BaselinesKvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BaselinesKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BaselinesKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BaselinesKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BaselinesKvCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required double value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BaselinesKvCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BaselinesKvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BaselinesKvTable,
      BaselinesKvData,
      $$BaselinesKvTableFilterComposer,
      $$BaselinesKvTableOrderingComposer,
      $$BaselinesKvTableAnnotationComposer,
      $$BaselinesKvTableCreateCompanionBuilder,
      $$BaselinesKvTableUpdateCompanionBuilder,
      (
        BaselinesKvData,
        BaseReferences<_$AppDatabase, $BaselinesKvTable, BaselinesKvData>,
      ),
      BaselinesKvData,
      PrefetchHooks Function()
    >;
typedef $$UserTriggerFlagsTblTableCreateCompanionBuilder =
    UserTriggerFlagsTblCompanion Function({
      required String moduleId,
      Value<bool> flagged,
      Value<double> weightOverride,
      Value<int> rowid,
    });
typedef $$UserTriggerFlagsTblTableUpdateCompanionBuilder =
    UserTriggerFlagsTblCompanion Function({
      Value<String> moduleId,
      Value<bool> flagged,
      Value<double> weightOverride,
      Value<int> rowid,
    });

class $$UserTriggerFlagsTblTableFilterComposer
    extends Composer<_$AppDatabase, $UserTriggerFlagsTblTable> {
  $$UserTriggerFlagsTblTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get moduleId => $composableBuilder(
    column: $table.moduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get flagged => $composableBuilder(
    column: $table.flagged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightOverride => $composableBuilder(
    column: $table.weightOverride,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserTriggerFlagsTblTableOrderingComposer
    extends Composer<_$AppDatabase, $UserTriggerFlagsTblTable> {
  $$UserTriggerFlagsTblTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get moduleId => $composableBuilder(
    column: $table.moduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get flagged => $composableBuilder(
    column: $table.flagged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightOverride => $composableBuilder(
    column: $table.weightOverride,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserTriggerFlagsTblTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserTriggerFlagsTblTable> {
  $$UserTriggerFlagsTblTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get moduleId =>
      $composableBuilder(column: $table.moduleId, builder: (column) => column);

  GeneratedColumn<bool> get flagged =>
      $composableBuilder(column: $table.flagged, builder: (column) => column);

  GeneratedColumn<double> get weightOverride => $composableBuilder(
    column: $table.weightOverride,
    builder: (column) => column,
  );
}

class $$UserTriggerFlagsTblTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserTriggerFlagsTblTable,
          UserTriggerFlagsTblData,
          $$UserTriggerFlagsTblTableFilterComposer,
          $$UserTriggerFlagsTblTableOrderingComposer,
          $$UserTriggerFlagsTblTableAnnotationComposer,
          $$UserTriggerFlagsTblTableCreateCompanionBuilder,
          $$UserTriggerFlagsTblTableUpdateCompanionBuilder,
          (
            UserTriggerFlagsTblData,
            BaseReferences<
              _$AppDatabase,
              $UserTriggerFlagsTblTable,
              UserTriggerFlagsTblData
            >,
          ),
          UserTriggerFlagsTblData,
          PrefetchHooks Function()
        > {
  $$UserTriggerFlagsTblTableTableManager(
    _$AppDatabase db,
    $UserTriggerFlagsTblTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserTriggerFlagsTblTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserTriggerFlagsTblTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserTriggerFlagsTblTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> moduleId = const Value.absent(),
                Value<bool> flagged = const Value.absent(),
                Value<double> weightOverride = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserTriggerFlagsTblCompanion(
                moduleId: moduleId,
                flagged: flagged,
                weightOverride: weightOverride,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String moduleId,
                Value<bool> flagged = const Value.absent(),
                Value<double> weightOverride = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserTriggerFlagsTblCompanion.insert(
                moduleId: moduleId,
                flagged: flagged,
                weightOverride: weightOverride,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserTriggerFlagsTblTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserTriggerFlagsTblTable,
      UserTriggerFlagsTblData,
      $$UserTriggerFlagsTblTableFilterComposer,
      $$UserTriggerFlagsTblTableOrderingComposer,
      $$UserTriggerFlagsTblTableAnnotationComposer,
      $$UserTriggerFlagsTblTableCreateCompanionBuilder,
      $$UserTriggerFlagsTblTableUpdateCompanionBuilder,
      (
        UserTriggerFlagsTblData,
        BaseReferences<
          _$AppDatabase,
          $UserTriggerFlagsTblTable,
          UserTriggerFlagsTblData
        >,
      ),
      UserTriggerFlagsTblData,
      PrefetchHooks Function()
    >;
typedef $$RiskAssessmentsTableCreateCompanionBuilder =
    RiskAssessmentsCompanion Function({
      Value<int> id,
      required DateTime targetDate,
      required String horizon,
      required int score,
      required String band,
      required DateTime computedAt,
      required int configVersion,
      required String contributorsJson,
      Value<bool> backfilled,
    });
typedef $$RiskAssessmentsTableUpdateCompanionBuilder =
    RiskAssessmentsCompanion Function({
      Value<int> id,
      Value<DateTime> targetDate,
      Value<String> horizon,
      Value<int> score,
      Value<String> band,
      Value<DateTime> computedAt,
      Value<int> configVersion,
      Value<String> contributorsJson,
      Value<bool> backfilled,
    });

class $$RiskAssessmentsTableFilterComposer
    extends Composer<_$AppDatabase, $RiskAssessmentsTable> {
  $$RiskAssessmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get horizon => $composableBuilder(
    column: $table.horizon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get band => $composableBuilder(
    column: $table.band,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get configVersion => $composableBuilder(
    column: $table.configVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contributorsJson => $composableBuilder(
    column: $table.contributorsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get backfilled => $composableBuilder(
    column: $table.backfilled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RiskAssessmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RiskAssessmentsTable> {
  $$RiskAssessmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get horizon => $composableBuilder(
    column: $table.horizon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get band => $composableBuilder(
    column: $table.band,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get configVersion => $composableBuilder(
    column: $table.configVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contributorsJson => $composableBuilder(
    column: $table.contributorsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get backfilled => $composableBuilder(
    column: $table.backfilled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RiskAssessmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RiskAssessmentsTable> {
  $$RiskAssessmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get horizon =>
      $composableBuilder(column: $table.horizon, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get band =>
      $composableBuilder(column: $table.band, builder: (column) => column);

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get configVersion => $composableBuilder(
    column: $table.configVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contributorsJson => $composableBuilder(
    column: $table.contributorsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get backfilled => $composableBuilder(
    column: $table.backfilled,
    builder: (column) => column,
  );
}

class $$RiskAssessmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RiskAssessmentsTable,
          RiskAssessment,
          $$RiskAssessmentsTableFilterComposer,
          $$RiskAssessmentsTableOrderingComposer,
          $$RiskAssessmentsTableAnnotationComposer,
          $$RiskAssessmentsTableCreateCompanionBuilder,
          $$RiskAssessmentsTableUpdateCompanionBuilder,
          (
            RiskAssessment,
            BaseReferences<
              _$AppDatabase,
              $RiskAssessmentsTable,
              RiskAssessment
            >,
          ),
          RiskAssessment,
          PrefetchHooks Function()
        > {
  $$RiskAssessmentsTableTableManager(
    _$AppDatabase db,
    $RiskAssessmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RiskAssessmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RiskAssessmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RiskAssessmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> targetDate = const Value.absent(),
                Value<String> horizon = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<String> band = const Value.absent(),
                Value<DateTime> computedAt = const Value.absent(),
                Value<int> configVersion = const Value.absent(),
                Value<String> contributorsJson = const Value.absent(),
                Value<bool> backfilled = const Value.absent(),
              }) => RiskAssessmentsCompanion(
                id: id,
                targetDate: targetDate,
                horizon: horizon,
                score: score,
                band: band,
                computedAt: computedAt,
                configVersion: configVersion,
                contributorsJson: contributorsJson,
                backfilled: backfilled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime targetDate,
                required String horizon,
                required int score,
                required String band,
                required DateTime computedAt,
                required int configVersion,
                required String contributorsJson,
                Value<bool> backfilled = const Value.absent(),
              }) => RiskAssessmentsCompanion.insert(
                id: id,
                targetDate: targetDate,
                horizon: horizon,
                score: score,
                band: band,
                computedAt: computedAt,
                configVersion: configVersion,
                contributorsJson: contributorsJson,
                backfilled: backfilled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RiskAssessmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RiskAssessmentsTable,
      RiskAssessment,
      $$RiskAssessmentsTableFilterComposer,
      $$RiskAssessmentsTableOrderingComposer,
      $$RiskAssessmentsTableAnnotationComposer,
      $$RiskAssessmentsTableCreateCompanionBuilder,
      $$RiskAssessmentsTableUpdateCompanionBuilder,
      (
        RiskAssessment,
        BaseReferences<_$AppDatabase, $RiskAssessmentsTable, RiskAssessment>,
      ),
      RiskAssessment,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$NotificationsSentTableCreateCompanionBuilder =
    NotificationsSentCompanion Function({
      Value<int> id,
      required DateTime targetDate,
      required String horizon,
      required String band,
      required DateTime sentAt,
    });
typedef $$NotificationsSentTableUpdateCompanionBuilder =
    NotificationsSentCompanion Function({
      Value<int> id,
      Value<DateTime> targetDate,
      Value<String> horizon,
      Value<String> band,
      Value<DateTime> sentAt,
    });

class $$NotificationsSentTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsSentTable> {
  $$NotificationsSentTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get horizon => $composableBuilder(
    column: $table.horizon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get band => $composableBuilder(
    column: $table.band,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsSentTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsSentTable> {
  $$NotificationsSentTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get horizon => $composableBuilder(
    column: $table.horizon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get band => $composableBuilder(
    column: $table.band,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsSentTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsSentTable> {
  $$NotificationsSentTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get horizon =>
      $composableBuilder(column: $table.horizon, builder: (column) => column);

  GeneratedColumn<String> get band =>
      $composableBuilder(column: $table.band, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$NotificationsSentTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsSentTable,
          NotificationsSentData,
          $$NotificationsSentTableFilterComposer,
          $$NotificationsSentTableOrderingComposer,
          $$NotificationsSentTableAnnotationComposer,
          $$NotificationsSentTableCreateCompanionBuilder,
          $$NotificationsSentTableUpdateCompanionBuilder,
          (
            NotificationsSentData,
            BaseReferences<
              _$AppDatabase,
              $NotificationsSentTable,
              NotificationsSentData
            >,
          ),
          NotificationsSentData,
          PrefetchHooks Function()
        > {
  $$NotificationsSentTableTableManager(
    _$AppDatabase db,
    $NotificationsSentTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsSentTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsSentTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsSentTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> targetDate = const Value.absent(),
                Value<String> horizon = const Value.absent(),
                Value<String> band = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
              }) => NotificationsSentCompanion(
                id: id,
                targetDate: targetDate,
                horizon: horizon,
                band: band,
                sentAt: sentAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime targetDate,
                required String horizon,
                required String band,
                required DateTime sentAt,
              }) => NotificationsSentCompanion.insert(
                id: id,
                targetDate: targetDate,
                horizon: horizon,
                band: band,
                sentAt: sentAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsSentTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsSentTable,
      NotificationsSentData,
      $$NotificationsSentTableFilterComposer,
      $$NotificationsSentTableOrderingComposer,
      $$NotificationsSentTableAnnotationComposer,
      $$NotificationsSentTableCreateCompanionBuilder,
      $$NotificationsSentTableUpdateCompanionBuilder,
      (
        NotificationsSentData,
        BaseReferences<
          _$AppDatabase,
          $NotificationsSentTable,
          NotificationsSentData
        >,
      ),
      NotificationsSentData,
      PrefetchHooks Function()
    >;
typedef $$PeriodsTableCreateCompanionBuilder =
    PeriodsCompanion Function({
      Value<int> id,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required int baselineSeverity,
    });
typedef $$PeriodsTableUpdateCompanionBuilder =
    PeriodsCompanion Function({
      Value<int> id,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> baselineSeverity,
    });

class $$PeriodsTableFilterComposer
    extends Composer<_$AppDatabase, $PeriodsTable> {
  $$PeriodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baselineSeverity => $composableBuilder(
    column: $table.baselineSeverity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeriodsTableOrderingComposer
    extends Composer<_$AppDatabase, $PeriodsTable> {
  $$PeriodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baselineSeverity => $composableBuilder(
    column: $table.baselineSeverity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeriodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeriodsTable> {
  $$PeriodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get baselineSeverity => $composableBuilder(
    column: $table.baselineSeverity,
    builder: (column) => column,
  );
}

class $$PeriodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeriodsTable,
          Period,
          $$PeriodsTableFilterComposer,
          $$PeriodsTableOrderingComposer,
          $$PeriodsTableAnnotationComposer,
          $$PeriodsTableCreateCompanionBuilder,
          $$PeriodsTableUpdateCompanionBuilder,
          (Period, BaseReferences<_$AppDatabase, $PeriodsTable, Period>),
          Period,
          PrefetchHooks Function()
        > {
  $$PeriodsTableTableManager(_$AppDatabase db, $PeriodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> baselineSeverity = const Value.absent(),
              }) => PeriodsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                baselineSeverity: baselineSeverity,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required int baselineSeverity,
              }) => PeriodsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                baselineSeverity: baselineSeverity,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeriodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeriodsTable,
      Period,
      $$PeriodsTableFilterComposer,
      $$PeriodsTableOrderingComposer,
      $$PeriodsTableAnnotationComposer,
      $$PeriodsTableCreateCompanionBuilder,
      $$PeriodsTableUpdateCompanionBuilder,
      (Period, BaseReferences<_$AppDatabase, $PeriodsTable, Period>),
      Period,
      PrefetchHooks Function()
    >;
typedef $$PeriodDaySeveritiesTableCreateCompanionBuilder =
    PeriodDaySeveritiesCompanion Function({
      required DateTime day,
      required int severity,
      Value<int> rowid,
    });
typedef $$PeriodDaySeveritiesTableUpdateCompanionBuilder =
    PeriodDaySeveritiesCompanion Function({
      Value<DateTime> day,
      Value<int> severity,
      Value<int> rowid,
    });

class $$PeriodDaySeveritiesTableFilterComposer
    extends Composer<_$AppDatabase, $PeriodDaySeveritiesTable> {
  $$PeriodDaySeveritiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeriodDaySeveritiesTableOrderingComposer
    extends Composer<_$AppDatabase, $PeriodDaySeveritiesTable> {
  $$PeriodDaySeveritiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeriodDaySeveritiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeriodDaySeveritiesTable> {
  $$PeriodDaySeveritiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);
}

class $$PeriodDaySeveritiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeriodDaySeveritiesTable,
          PeriodDaySeverity,
          $$PeriodDaySeveritiesTableFilterComposer,
          $$PeriodDaySeveritiesTableOrderingComposer,
          $$PeriodDaySeveritiesTableAnnotationComposer,
          $$PeriodDaySeveritiesTableCreateCompanionBuilder,
          $$PeriodDaySeveritiesTableUpdateCompanionBuilder,
          (
            PeriodDaySeverity,
            BaseReferences<
              _$AppDatabase,
              $PeriodDaySeveritiesTable,
              PeriodDaySeverity
            >,
          ),
          PeriodDaySeverity,
          PrefetchHooks Function()
        > {
  $$PeriodDaySeveritiesTableTableManager(
    _$AppDatabase db,
    $PeriodDaySeveritiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodDaySeveritiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodDaySeveritiesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PeriodDaySeveritiesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> day = const Value.absent(),
                Value<int> severity = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeriodDaySeveritiesCompanion(
                day: day,
                severity: severity,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime day,
                required int severity,
                Value<int> rowid = const Value.absent(),
              }) => PeriodDaySeveritiesCompanion.insert(
                day: day,
                severity: severity,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeriodDaySeveritiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeriodDaySeveritiesTable,
      PeriodDaySeverity,
      $$PeriodDaySeveritiesTableFilterComposer,
      $$PeriodDaySeveritiesTableOrderingComposer,
      $$PeriodDaySeveritiesTableAnnotationComposer,
      $$PeriodDaySeveritiesTableCreateCompanionBuilder,
      $$PeriodDaySeveritiesTableUpdateCompanionBuilder,
      (
        PeriodDaySeverity,
        BaseReferences<
          _$AppDatabase,
          $PeriodDaySeveritiesTable,
          PeriodDaySeverity
        >,
      ),
      PeriodDaySeverity,
      PrefetchHooks Function()
    >;
typedef $$ManualSleepRecordsTableCreateCompanionBuilder =
    ManualSleepRecordsCompanion Function({
      required DateTime night,
      required DateTime sleepStart,
      required int totalSleepMinutes,
      Value<double?> efficiency,
      Value<int> rowid,
    });
typedef $$ManualSleepRecordsTableUpdateCompanionBuilder =
    ManualSleepRecordsCompanion Function({
      Value<DateTime> night,
      Value<DateTime> sleepStart,
      Value<int> totalSleepMinutes,
      Value<double?> efficiency,
      Value<int> rowid,
    });

class $$ManualSleepRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ManualSleepRecordsTable> {
  $$ManualSleepRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get night => $composableBuilder(
    column: $table.night,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sleepStart => $composableBuilder(
    column: $table.sleepStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSleepMinutes => $composableBuilder(
    column: $table.totalSleepMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get efficiency => $composableBuilder(
    column: $table.efficiency,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ManualSleepRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ManualSleepRecordsTable> {
  $$ManualSleepRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get night => $composableBuilder(
    column: $table.night,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sleepStart => $composableBuilder(
    column: $table.sleepStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSleepMinutes => $composableBuilder(
    column: $table.totalSleepMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get efficiency => $composableBuilder(
    column: $table.efficiency,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ManualSleepRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ManualSleepRecordsTable> {
  $$ManualSleepRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get night =>
      $composableBuilder(column: $table.night, builder: (column) => column);

  GeneratedColumn<DateTime> get sleepStart => $composableBuilder(
    column: $table.sleepStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSleepMinutes => $composableBuilder(
    column: $table.totalSleepMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get efficiency => $composableBuilder(
    column: $table.efficiency,
    builder: (column) => column,
  );
}

class $$ManualSleepRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ManualSleepRecordsTable,
          ManualSleepRecord,
          $$ManualSleepRecordsTableFilterComposer,
          $$ManualSleepRecordsTableOrderingComposer,
          $$ManualSleepRecordsTableAnnotationComposer,
          $$ManualSleepRecordsTableCreateCompanionBuilder,
          $$ManualSleepRecordsTableUpdateCompanionBuilder,
          (
            ManualSleepRecord,
            BaseReferences<
              _$AppDatabase,
              $ManualSleepRecordsTable,
              ManualSleepRecord
            >,
          ),
          ManualSleepRecord,
          PrefetchHooks Function()
        > {
  $$ManualSleepRecordsTableTableManager(
    _$AppDatabase db,
    $ManualSleepRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManualSleepRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManualSleepRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManualSleepRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> night = const Value.absent(),
                Value<DateTime> sleepStart = const Value.absent(),
                Value<int> totalSleepMinutes = const Value.absent(),
                Value<double?> efficiency = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManualSleepRecordsCompanion(
                night: night,
                sleepStart: sleepStart,
                totalSleepMinutes: totalSleepMinutes,
                efficiency: efficiency,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime night,
                required DateTime sleepStart,
                required int totalSleepMinutes,
                Value<double?> efficiency = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManualSleepRecordsCompanion.insert(
                night: night,
                sleepStart: sleepStart,
                totalSleepMinutes: totalSleepMinutes,
                efficiency: efficiency,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ManualSleepRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ManualSleepRecordsTable,
      ManualSleepRecord,
      $$ManualSleepRecordsTableFilterComposer,
      $$ManualSleepRecordsTableOrderingComposer,
      $$ManualSleepRecordsTableAnnotationComposer,
      $$ManualSleepRecordsTableCreateCompanionBuilder,
      $$ManualSleepRecordsTableUpdateCompanionBuilder,
      (
        ManualSleepRecord,
        BaseReferences<
          _$AppDatabase,
          $ManualSleepRecordsTable,
          ManualSleepRecord
        >,
      ),
      ManualSleepRecord,
      PrefetchHooks Function()
    >;
typedef $$DayLocationOverridesTableCreateCompanionBuilder =
    DayLocationOverridesCompanion Function({
      required DateTime day,
      required double lat,
      required double lon,
      required String displayName,
      required DateTime setAt,
      Value<int> rowid,
    });
typedef $$DayLocationOverridesTableUpdateCompanionBuilder =
    DayLocationOverridesCompanion Function({
      Value<DateTime> day,
      Value<double> lat,
      Value<double> lon,
      Value<String> displayName,
      Value<DateTime> setAt,
      Value<int> rowid,
    });

class $$DayLocationOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $DayLocationOverridesTable> {
  $$DayLocationOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get setAt => $composableBuilder(
    column: $table.setAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayLocationOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $DayLocationOverridesTable> {
  $$DayLocationOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get setAt => $composableBuilder(
    column: $table.setAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayLocationOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayLocationOverridesTable> {
  $$DayLocationOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get setAt =>
      $composableBuilder(column: $table.setAt, builder: (column) => column);
}

class $$DayLocationOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayLocationOverridesTable,
          DayLocationOverride,
          $$DayLocationOverridesTableFilterComposer,
          $$DayLocationOverridesTableOrderingComposer,
          $$DayLocationOverridesTableAnnotationComposer,
          $$DayLocationOverridesTableCreateCompanionBuilder,
          $$DayLocationOverridesTableUpdateCompanionBuilder,
          (
            DayLocationOverride,
            BaseReferences<
              _$AppDatabase,
              $DayLocationOverridesTable,
              DayLocationOverride
            >,
          ),
          DayLocationOverride,
          PrefetchHooks Function()
        > {
  $$DayLocationOverridesTableTableManager(
    _$AppDatabase db,
    $DayLocationOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayLocationOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayLocationOverridesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DayLocationOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<DateTime> day = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<DateTime> setAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayLocationOverridesCompanion(
                day: day,
                lat: lat,
                lon: lon,
                displayName: displayName,
                setAt: setAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime day,
                required double lat,
                required double lon,
                required String displayName,
                required DateTime setAt,
                Value<int> rowid = const Value.absent(),
              }) => DayLocationOverridesCompanion.insert(
                day: day,
                lat: lat,
                lon: lon,
                displayName: displayName,
                setAt: setAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayLocationOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayLocationOverridesTable,
      DayLocationOverride,
      $$DayLocationOverridesTableFilterComposer,
      $$DayLocationOverridesTableOrderingComposer,
      $$DayLocationOverridesTableAnnotationComposer,
      $$DayLocationOverridesTableCreateCompanionBuilder,
      $$DayLocationOverridesTableUpdateCompanionBuilder,
      (
        DayLocationOverride,
        BaseReferences<
          _$AppDatabase,
          $DayLocationOverridesTable,
          DayLocationOverride
        >,
      ),
      DayLocationOverride,
      PrefetchHooks Function()
    >;
typedef $$OuraSleepTableCreateCompanionBuilder =
    OuraSleepCompanion Function({
      required String id,
      required DateTime day,
      Value<int?> lowestHeartRate,
      Value<int?> restlessPeriods,
      Value<double?> averageHeartRate,
      Value<int?> averageHrv,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$OuraSleepTableUpdateCompanionBuilder =
    OuraSleepCompanion Function({
      Value<String> id,
      Value<DateTime> day,
      Value<int?> lowestHeartRate,
      Value<int?> restlessPeriods,
      Value<double?> averageHeartRate,
      Value<int?> averageHrv,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$OuraSleepTableFilterComposer
    extends Composer<_$AppDatabase, $OuraSleepTable> {
  $$OuraSleepTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowestHeartRate => $composableBuilder(
    column: $table.lowestHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restlessPeriods => $composableBuilder(
    column: $table.restlessPeriods,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageHeartRate => $composableBuilder(
    column: $table.averageHeartRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get averageHrv => $composableBuilder(
    column: $table.averageHrv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OuraSleepTableOrderingComposer
    extends Composer<_$AppDatabase, $OuraSleepTable> {
  $$OuraSleepTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowestHeartRate => $composableBuilder(
    column: $table.lowestHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restlessPeriods => $composableBuilder(
    column: $table.restlessPeriods,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageHeartRate => $composableBuilder(
    column: $table.averageHeartRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get averageHrv => $composableBuilder(
    column: $table.averageHrv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OuraSleepTableAnnotationComposer
    extends Composer<_$AppDatabase, $OuraSleepTable> {
  $$OuraSleepTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get lowestHeartRate => $composableBuilder(
    column: $table.lowestHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restlessPeriods => $composableBuilder(
    column: $table.restlessPeriods,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageHeartRate => $composableBuilder(
    column: $table.averageHeartRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get averageHrv => $composableBuilder(
    column: $table.averageHrv,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$OuraSleepTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OuraSleepTable,
          OuraSleepData,
          $$OuraSleepTableFilterComposer,
          $$OuraSleepTableOrderingComposer,
          $$OuraSleepTableAnnotationComposer,
          $$OuraSleepTableCreateCompanionBuilder,
          $$OuraSleepTableUpdateCompanionBuilder,
          (
            OuraSleepData,
            BaseReferences<_$AppDatabase, $OuraSleepTable, OuraSleepData>,
          ),
          OuraSleepData,
          PrefetchHooks Function()
        > {
  $$OuraSleepTableTableManager(_$AppDatabase db, $OuraSleepTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OuraSleepTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OuraSleepTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OuraSleepTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int?> lowestHeartRate = const Value.absent(),
                Value<int?> restlessPeriods = const Value.absent(),
                Value<double?> averageHeartRate = const Value.absent(),
                Value<int?> averageHrv = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OuraSleepCompanion(
                id: id,
                day: day,
                lowestHeartRate: lowestHeartRate,
                restlessPeriods: restlessPeriods,
                averageHeartRate: averageHeartRate,
                averageHrv: averageHrv,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime day,
                Value<int?> lowestHeartRate = const Value.absent(),
                Value<int?> restlessPeriods = const Value.absent(),
                Value<double?> averageHeartRate = const Value.absent(),
                Value<int?> averageHrv = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => OuraSleepCompanion.insert(
                id: id,
                day: day,
                lowestHeartRate: lowestHeartRate,
                restlessPeriods: restlessPeriods,
                averageHeartRate: averageHeartRate,
                averageHrv: averageHrv,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OuraSleepTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OuraSleepTable,
      OuraSleepData,
      $$OuraSleepTableFilterComposer,
      $$OuraSleepTableOrderingComposer,
      $$OuraSleepTableAnnotationComposer,
      $$OuraSleepTableCreateCompanionBuilder,
      $$OuraSleepTableUpdateCompanionBuilder,
      (
        OuraSleepData,
        BaseReferences<_$AppDatabase, $OuraSleepTable, OuraSleepData>,
      ),
      OuraSleepData,
      PrefetchHooks Function()
    >;
typedef $$OuraDailySleepTableCreateCompanionBuilder =
    OuraDailySleepCompanion Function({
      required String id,
      required DateTime day,
      Value<int?> score,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$OuraDailySleepTableUpdateCompanionBuilder =
    OuraDailySleepCompanion Function({
      Value<String> id,
      Value<DateTime> day,
      Value<int?> score,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$OuraDailySleepTableFilterComposer
    extends Composer<_$AppDatabase, $OuraDailySleepTable> {
  $$OuraDailySleepTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OuraDailySleepTableOrderingComposer
    extends Composer<_$AppDatabase, $OuraDailySleepTable> {
  $$OuraDailySleepTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OuraDailySleepTableAnnotationComposer
    extends Composer<_$AppDatabase, $OuraDailySleepTable> {
  $$OuraDailySleepTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$OuraDailySleepTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OuraDailySleepTable,
          OuraDailySleepData,
          $$OuraDailySleepTableFilterComposer,
          $$OuraDailySleepTableOrderingComposer,
          $$OuraDailySleepTableAnnotationComposer,
          $$OuraDailySleepTableCreateCompanionBuilder,
          $$OuraDailySleepTableUpdateCompanionBuilder,
          (
            OuraDailySleepData,
            BaseReferences<
              _$AppDatabase,
              $OuraDailySleepTable,
              OuraDailySleepData
            >,
          ),
          OuraDailySleepData,
          PrefetchHooks Function()
        > {
  $$OuraDailySleepTableTableManager(
    _$AppDatabase db,
    $OuraDailySleepTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OuraDailySleepTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OuraDailySleepTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OuraDailySleepTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OuraDailySleepCompanion(
                id: id,
                day: day,
                score: score,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime day,
                Value<int?> score = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => OuraDailySleepCompanion.insert(
                id: id,
                day: day,
                score: score,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OuraDailySleepTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OuraDailySleepTable,
      OuraDailySleepData,
      $$OuraDailySleepTableFilterComposer,
      $$OuraDailySleepTableOrderingComposer,
      $$OuraDailySleepTableAnnotationComposer,
      $$OuraDailySleepTableCreateCompanionBuilder,
      $$OuraDailySleepTableUpdateCompanionBuilder,
      (
        OuraDailySleepData,
        BaseReferences<_$AppDatabase, $OuraDailySleepTable, OuraDailySleepData>,
      ),
      OuraDailySleepData,
      PrefetchHooks Function()
    >;
typedef $$OuraActivityTableCreateCompanionBuilder =
    OuraActivityCompanion Function({
      required String id,
      required DateTime day,
      Value<int?> activityScore,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$OuraActivityTableUpdateCompanionBuilder =
    OuraActivityCompanion Function({
      Value<String> id,
      Value<DateTime> day,
      Value<int?> activityScore,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$OuraActivityTableFilterComposer
    extends Composer<_$AppDatabase, $OuraActivityTable> {
  $$OuraActivityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activityScore => $composableBuilder(
    column: $table.activityScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OuraActivityTableOrderingComposer
    extends Composer<_$AppDatabase, $OuraActivityTable> {
  $$OuraActivityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activityScore => $composableBuilder(
    column: $table.activityScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OuraActivityTableAnnotationComposer
    extends Composer<_$AppDatabase, $OuraActivityTable> {
  $$OuraActivityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get activityScore => $composableBuilder(
    column: $table.activityScore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$OuraActivityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OuraActivityTable,
          OuraActivityData,
          $$OuraActivityTableFilterComposer,
          $$OuraActivityTableOrderingComposer,
          $$OuraActivityTableAnnotationComposer,
          $$OuraActivityTableCreateCompanionBuilder,
          $$OuraActivityTableUpdateCompanionBuilder,
          (
            OuraActivityData,
            BaseReferences<_$AppDatabase, $OuraActivityTable, OuraActivityData>,
          ),
          OuraActivityData,
          PrefetchHooks Function()
        > {
  $$OuraActivityTableTableManager(_$AppDatabase db, $OuraActivityTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OuraActivityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OuraActivityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OuraActivityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int?> activityScore = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OuraActivityCompanion(
                id: id,
                day: day,
                activityScore: activityScore,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime day,
                Value<int?> activityScore = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => OuraActivityCompanion.insert(
                id: id,
                day: day,
                activityScore: activityScore,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OuraActivityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OuraActivityTable,
      OuraActivityData,
      $$OuraActivityTableFilterComposer,
      $$OuraActivityTableOrderingComposer,
      $$OuraActivityTableAnnotationComposer,
      $$OuraActivityTableCreateCompanionBuilder,
      $$OuraActivityTableUpdateCompanionBuilder,
      (
        OuraActivityData,
        BaseReferences<_$AppDatabase, $OuraActivityTable, OuraActivityData>,
      ),
      OuraActivityData,
      PrefetchHooks Function()
    >;
typedef $$OuraReadinessTableCreateCompanionBuilder =
    OuraReadinessCompanion Function({
      required String id,
      required DateTime day,
      Value<int?> readinessScore,
      Value<double?> temperatureDeviation,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$OuraReadinessTableUpdateCompanionBuilder =
    OuraReadinessCompanion Function({
      Value<String> id,
      Value<DateTime> day,
      Value<int?> readinessScore,
      Value<double?> temperatureDeviation,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$OuraReadinessTableFilterComposer
    extends Composer<_$AppDatabase, $OuraReadinessTable> {
  $$OuraReadinessTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readinessScore => $composableBuilder(
    column: $table.readinessScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureDeviation => $composableBuilder(
    column: $table.temperatureDeviation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OuraReadinessTableOrderingComposer
    extends Composer<_$AppDatabase, $OuraReadinessTable> {
  $$OuraReadinessTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readinessScore => $composableBuilder(
    column: $table.readinessScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureDeviation => $composableBuilder(
    column: $table.temperatureDeviation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OuraReadinessTableAnnotationComposer
    extends Composer<_$AppDatabase, $OuraReadinessTable> {
  $$OuraReadinessTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get readinessScore => $composableBuilder(
    column: $table.readinessScore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperatureDeviation => $composableBuilder(
    column: $table.temperatureDeviation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$OuraReadinessTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OuraReadinessTable,
          OuraReadinessData,
          $$OuraReadinessTableFilterComposer,
          $$OuraReadinessTableOrderingComposer,
          $$OuraReadinessTableAnnotationComposer,
          $$OuraReadinessTableCreateCompanionBuilder,
          $$OuraReadinessTableUpdateCompanionBuilder,
          (
            OuraReadinessData,
            BaseReferences<
              _$AppDatabase,
              $OuraReadinessTable,
              OuraReadinessData
            >,
          ),
          OuraReadinessData,
          PrefetchHooks Function()
        > {
  $$OuraReadinessTableTableManager(_$AppDatabase db, $OuraReadinessTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OuraReadinessTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OuraReadinessTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OuraReadinessTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int?> readinessScore = const Value.absent(),
                Value<double?> temperatureDeviation = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OuraReadinessCompanion(
                id: id,
                day: day,
                readinessScore: readinessScore,
                temperatureDeviation: temperatureDeviation,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime day,
                Value<int?> readinessScore = const Value.absent(),
                Value<double?> temperatureDeviation = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => OuraReadinessCompanion.insert(
                id: id,
                day: day,
                readinessScore: readinessScore,
                temperatureDeviation: temperatureDeviation,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OuraReadinessTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OuraReadinessTable,
      OuraReadinessData,
      $$OuraReadinessTableFilterComposer,
      $$OuraReadinessTableOrderingComposer,
      $$OuraReadinessTableAnnotationComposer,
      $$OuraReadinessTableCreateCompanionBuilder,
      $$OuraReadinessTableUpdateCompanionBuilder,
      (
        OuraReadinessData,
        BaseReferences<_$AppDatabase, $OuraReadinessTable, OuraReadinessData>,
      ),
      OuraReadinessData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AttacksTableTableManager get attacks =>
      $$AttacksTableTableManager(_db, _db.attacks);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$WeatherSnapshotsTableTableManager get weatherSnapshots =>
      $$WeatherSnapshotsTableTableManager(_db, _db.weatherSnapshots);
  $$BaselinesKvTableTableManager get baselinesKv =>
      $$BaselinesKvTableTableManager(_db, _db.baselinesKv);
  $$UserTriggerFlagsTblTableTableManager get userTriggerFlagsTbl =>
      $$UserTriggerFlagsTblTableTableManager(_db, _db.userTriggerFlagsTbl);
  $$RiskAssessmentsTableTableManager get riskAssessments =>
      $$RiskAssessmentsTableTableManager(_db, _db.riskAssessments);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$NotificationsSentTableTableManager get notificationsSent =>
      $$NotificationsSentTableTableManager(_db, _db.notificationsSent);
  $$PeriodsTableTableManager get periods =>
      $$PeriodsTableTableManager(_db, _db.periods);
  $$PeriodDaySeveritiesTableTableManager get periodDaySeverities =>
      $$PeriodDaySeveritiesTableTableManager(_db, _db.periodDaySeverities);
  $$ManualSleepRecordsTableTableManager get manualSleepRecords =>
      $$ManualSleepRecordsTableTableManager(_db, _db.manualSleepRecords);
  $$DayLocationOverridesTableTableManager get dayLocationOverrides =>
      $$DayLocationOverridesTableTableManager(_db, _db.dayLocationOverrides);
  $$OuraSleepTableTableManager get ouraSleep =>
      $$OuraSleepTableTableManager(_db, _db.ouraSleep);
  $$OuraDailySleepTableTableManager get ouraDailySleep =>
      $$OuraDailySleepTableTableManager(_db, _db.ouraDailySleep);
  $$OuraActivityTableTableManager get ouraActivity =>
      $$OuraActivityTableTableManager(_db, _db.ouraActivity);
  $$OuraReadinessTableTableManager get ouraReadiness =>
      $$OuraReadinessTableTableManager(_db, _db.ouraReadiness);
}
