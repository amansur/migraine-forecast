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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fetchedAt,
    lat,
    lon,
    forecastJson,
    airQualityJson,
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
  const WeatherSnapshot({
    required this.id,
    required this.fetchedAt,
    required this.lat,
    required this.lon,
    required this.forecastJson,
    this.airQualityJson,
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
    };
  }

  WeatherSnapshot copyWith({
    int? id,
    DateTime? fetchedAt,
    double? lat,
    double? lon,
    String? forecastJson,
    Value<String?> airQualityJson = const Value.absent(),
  }) => WeatherSnapshot(
    id: id ?? this.id,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    forecastJson: forecastJson ?? this.forecastJson,
    airQualityJson: airQualityJson.present
        ? airQualityJson.value
        : this.airQualityJson,
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
          ..write('airQualityJson: $airQualityJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fetchedAt, lat, lon, forecastJson, airQualityJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherSnapshot &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.forecastJson == this.forecastJson &&
          other.airQualityJson == this.airQualityJson);
}

class WeatherSnapshotsCompanion extends UpdateCompanion<WeatherSnapshot> {
  final Value<int> id;
  final Value<DateTime> fetchedAt;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String> forecastJson;
  final Value<String?> airQualityJson;
  const WeatherSnapshotsCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.forecastJson = const Value.absent(),
    this.airQualityJson = const Value.absent(),
  });
  WeatherSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime fetchedAt,
    required double lat,
    required double lon,
    required String forecastJson,
    this.airQualityJson = const Value.absent(),
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
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (forecastJson != null) 'forecast_json': forecastJson,
      if (airQualityJson != null) 'air_quality_json': airQualityJson,
    });
  }

  WeatherSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? fetchedAt,
    Value<double>? lat,
    Value<double>? lon,
    Value<String>? forecastJson,
    Value<String?>? airQualityJson,
  }) {
    return WeatherSnapshotsCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      forecastJson: forecastJson ?? this.forecastJson,
      airQualityJson: airQualityJson ?? this.airQualityJson,
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
          ..write('airQualityJson: $airQualityJson')
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
    });
typedef $$WeatherSnapshotsTableUpdateCompanionBuilder =
    WeatherSnapshotsCompanion Function({
      Value<int> id,
      Value<DateTime> fetchedAt,
      Value<double> lat,
      Value<double> lon,
      Value<String> forecastJson,
      Value<String?> airQualityJson,
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
              }) => WeatherSnapshotsCompanion(
                id: id,
                fetchedAt: fetchedAt,
                lat: lat,
                lon: lon,
                forecastJson: forecastJson,
                airQualityJson: airQualityJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime fetchedAt,
                required double lat,
                required double lon,
                required String forecastJson,
                Value<String?> airQualityJson = const Value.absent(),
              }) => WeatherSnapshotsCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                lat: lat,
                lon: lon,
                forecastJson: forecastJson,
                airQualityJson: airQualityJson,
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
}
