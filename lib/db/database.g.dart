// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NirDaysTable extends NirDays with TableInfo<$NirDaysTable, DayUsage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NirDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
    'device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta('deviceName');
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _rxMeta = const VerificationMeta('rx');
  @override
  late final GeneratedColumn<int> rx = GeneratedColumn<int>(
    'rx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _txMeta = const VerificationMeta('tx');
  @override
  late final GeneratedColumn<int> tx = GeneratedColumn<int>(
    'tx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('recorder'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, hlc, deleted, device, deviceName, day, kind, rx, tx, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nir_days';
  @override
  VerificationContext validateIntegrity(Insertable<DayUsage> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('device')) {
      context.handle(_deviceMeta, device.isAcceptableOrUnknown(data['device']!, _deviceMeta));
    } else if (isInserting) {
      context.missing(_deviceMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('rx')) {
      context.handle(_rxMeta, rx.isAcceptableOrUnknown(data['rx']!, _rxMeta));
    }
    if (data.containsKey('tx')) {
      context.handle(_txMeta, tx.isAcceptableOrUnknown(data['tx']!, _txMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta, source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayUsage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayUsage(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      device: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}device'])!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}day'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      rx: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}rx'])!,
      tx: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}tx'])!,
      source: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source'])!,
    );
  }

  @override
  $NirDaysTable createAlias(String alias) {
    return $NirDaysTable(attachedDatabase, alias);
  }
}

class DayUsage extends DataClass implements Insertable<DayUsage> {
  final String id;
  final String hlc;
  final bool deleted;

  /// The measuring device's id (Store.deviceId) and the name it had then.
  final String device;
  final String deviceName;
  final String day;

  /// wifi | ethernet | mobile | other
  final String kind;
  final int rx;
  final int tx;

  /// Where the numbers come from: recorder (this app, while it runs),
  /// vnstat (Linux) or android (the system's network statistics).
  final String source;
  const DayUsage({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.device,
    required this.deviceName,
    required this.day,
    required this.kind,
    required this.rx,
    required this.tx,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['device'] = Variable<String>(device);
    map['device_name'] = Variable<String>(deviceName);
    map['day'] = Variable<String>(day);
    map['kind'] = Variable<String>(kind);
    map['rx'] = Variable<int>(rx);
    map['tx'] = Variable<int>(tx);
    map['source'] = Variable<String>(source);
    return map;
  }

  NirDaysCompanion toCompanion(bool nullToAbsent) {
    return NirDaysCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      device: Value(device),
      deviceName: Value(deviceName),
      day: Value(day),
      kind: Value(kind),
      rx: Value(rx),
      tx: Value(tx),
      source: Value(source),
    );
  }

  factory DayUsage.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayUsage(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      device: serializer.fromJson<String>(json['device']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      day: serializer.fromJson<String>(json['day']),
      kind: serializer.fromJson<String>(json['kind']),
      rx: serializer.fromJson<int>(json['rx']),
      tx: serializer.fromJson<int>(json['tx']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'device': serializer.toJson<String>(device),
      'deviceName': serializer.toJson<String>(deviceName),
      'day': serializer.toJson<String>(day),
      'kind': serializer.toJson<String>(kind),
      'rx': serializer.toJson<int>(rx),
      'tx': serializer.toJson<int>(tx),
      'source': serializer.toJson<String>(source),
    };
  }

  DayUsage copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? device,
    String? deviceName,
    String? day,
    String? kind,
    int? rx,
    int? tx,
    String? source,
  }) => DayUsage(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    device: device ?? this.device,
    deviceName: deviceName ?? this.deviceName,
    day: day ?? this.day,
    kind: kind ?? this.kind,
    rx: rx ?? this.rx,
    tx: tx ?? this.tx,
    source: source ?? this.source,
  );
  DayUsage copyWithCompanion(NirDaysCompanion data) {
    return DayUsage(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      device: data.device.present ? data.device.value : this.device,
      deviceName: data.deviceName.present ? data.deviceName.value : this.deviceName,
      day: data.day.present ? data.day.value : this.day,
      kind: data.kind.present ? data.kind.value : this.kind,
      rx: data.rx.present ? data.rx.value : this.rx,
      tx: data.tx.present ? data.tx.value : this.tx,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayUsage(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('device: $device, ')
          ..write('deviceName: $deviceName, ')
          ..write('day: $day, ')
          ..write('kind: $kind, ')
          ..write('rx: $rx, ')
          ..write('tx: $tx, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, device, deviceName, day, kind, rx, tx, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayUsage &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.device == this.device &&
          other.deviceName == this.deviceName &&
          other.day == this.day &&
          other.kind == this.kind &&
          other.rx == this.rx &&
          other.tx == this.tx &&
          other.source == this.source);
}

class NirDaysCompanion extends UpdateCompanion<DayUsage> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> device;
  final Value<String> deviceName;
  final Value<String> day;
  final Value<String> kind;
  final Value<int> rx;
  final Value<int> tx;
  final Value<String> source;
  final Value<int> rowid;
  const NirDaysCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.device = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.day = const Value.absent(),
    this.kind = const Value.absent(),
    this.rx = const Value.absent(),
    this.tx = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NirDaysCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String device,
    this.deviceName = const Value.absent(),
    required String day,
    required String kind,
    this.rx = const Value.absent(),
    this.tx = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       device = Value(device),
       day = Value(day),
       kind = Value(kind);
  static Insertable<DayUsage> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? device,
    Expression<String>? deviceName,
    Expression<String>? day,
    Expression<String>? kind,
    Expression<int>? rx,
    Expression<int>? tx,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (device != null) 'device': device,
      if (deviceName != null) 'device_name': deviceName,
      if (day != null) 'day': day,
      if (kind != null) 'kind': kind,
      if (rx != null) 'rx': rx,
      if (tx != null) 'tx': tx,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NirDaysCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? device,
    Value<String>? deviceName,
    Value<String>? day,
    Value<String>? kind,
    Value<int>? rx,
    Value<int>? tx,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return NirDaysCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      device: device ?? this.device,
      deviceName: deviceName ?? this.deviceName,
      day: day ?? this.day,
      kind: kind ?? this.kind,
      rx: rx ?? this.rx,
      tx: tx ?? this.tx,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rx.present) {
      map['rx'] = Variable<int>(rx.value);
    }
    if (tx.present) {
      map['tx'] = Variable<int>(tx.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NirDaysCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('device: $device, ')
          ..write('deviceName: $deviceName, ')
          ..write('day: $day, ')
          ..write('kind: $kind, ')
          ..write('rx: $rx, ')
          ..write('tx: $tx, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NirAppsTable extends NirApps with TableInfo<$NirAppsTable, AppUsage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NirAppsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
    'device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta('deviceName');
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appMeta = const VerificationMeta('app');
  @override
  late final GeneratedColumn<String> app = GeneratedColumn<String>(
    'app',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _rxMeta = const VerificationMeta('rx');
  @override
  late final GeneratedColumn<int> rx = GeneratedColumn<int>(
    'rx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _txMeta = const VerificationMeta('tx');
  @override
  late final GeneratedColumn<int> tx = GeneratedColumn<int>(
    'tx',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fgMeta = const VerificationMeta('fg');
  @override
  late final GeneratedColumn<int> fg = GeneratedColumn<int>(
    'fg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    device,
    deviceName,
    day,
    app,
    name,
    kind,
    rx,
    tx,
    fg,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nir_apps';
  @override
  VerificationContext validateIntegrity(Insertable<AppUsage> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('device')) {
      context.handle(_deviceMeta, device.isAcceptableOrUnknown(data['device']!, _deviceMeta));
    } else if (isInserting) {
      context.missing(_deviceMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('app')) {
      context.handle(_appMeta, app.isAcceptableOrUnknown(data['app']!, _appMeta));
    } else if (isInserting) {
      context.missing(_appMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('rx')) {
      context.handle(_rxMeta, rx.isAcceptableOrUnknown(data['rx']!, _rxMeta));
    }
    if (data.containsKey('tx')) {
      context.handle(_txMeta, tx.isAcceptableOrUnknown(data['tx']!, _txMeta));
    }
    if (data.containsKey('fg')) {
      context.handle(_fgMeta, fg.isAcceptableOrUnknown(data['fg']!, _fgMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppUsage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppUsage(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      device: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}device'])!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}day'])!,
      app: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}app'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      rx: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}rx'])!,
      tx: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}tx'])!,
      fg: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}fg']),
    );
  }

  @override
  $NirAppsTable createAlias(String alias) {
    return $NirAppsTable(attachedDatabase, alias);
  }
}

class AppUsage extends DataClass implements Insertable<AppUsage> {
  final String id;
  final String hlc;
  final bool deleted;
  final String device;
  final String deviceName;
  final String day;

  /// What the system knows the program by: an Android package name, a
  /// program's path on Linux, a Windows attribution id, or `uid:<n>` and
  /// the like for traffic no single app owns.
  final String app;
  final String name;

  /// wifi | ethernet | mobile | other
  final String kind;
  final int rx;
  final int tx;

  /// Bytes (both ways) moved while the app was on screen; null where the
  /// system does not say (only Android does).
  final int? fg;
  const AppUsage({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.device,
    required this.deviceName,
    required this.day,
    required this.app,
    required this.name,
    required this.kind,
    required this.rx,
    required this.tx,
    this.fg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['device'] = Variable<String>(device);
    map['device_name'] = Variable<String>(deviceName);
    map['day'] = Variable<String>(day);
    map['app'] = Variable<String>(app);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['rx'] = Variable<int>(rx);
    map['tx'] = Variable<int>(tx);
    if (!nullToAbsent || fg != null) {
      map['fg'] = Variable<int>(fg);
    }
    return map;
  }

  NirAppsCompanion toCompanion(bool nullToAbsent) {
    return NirAppsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      device: Value(device),
      deviceName: Value(deviceName),
      day: Value(day),
      app: Value(app),
      name: Value(name),
      kind: Value(kind),
      rx: Value(rx),
      tx: Value(tx),
      fg: fg == null && nullToAbsent ? const Value.absent() : Value(fg),
    );
  }

  factory AppUsage.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppUsage(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      device: serializer.fromJson<String>(json['device']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      day: serializer.fromJson<String>(json['day']),
      app: serializer.fromJson<String>(json['app']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      rx: serializer.fromJson<int>(json['rx']),
      tx: serializer.fromJson<int>(json['tx']),
      fg: serializer.fromJson<int?>(json['fg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'device': serializer.toJson<String>(device),
      'deviceName': serializer.toJson<String>(deviceName),
      'day': serializer.toJson<String>(day),
      'app': serializer.toJson<String>(app),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'rx': serializer.toJson<int>(rx),
      'tx': serializer.toJson<int>(tx),
      'fg': serializer.toJson<int?>(fg),
    };
  }

  AppUsage copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? device,
    String? deviceName,
    String? day,
    String? app,
    String? name,
    String? kind,
    int? rx,
    int? tx,
    Value<int?> fg = const Value.absent(),
  }) => AppUsage(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    device: device ?? this.device,
    deviceName: deviceName ?? this.deviceName,
    day: day ?? this.day,
    app: app ?? this.app,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    rx: rx ?? this.rx,
    tx: tx ?? this.tx,
    fg: fg.present ? fg.value : this.fg,
  );
  AppUsage copyWithCompanion(NirAppsCompanion data) {
    return AppUsage(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      device: data.device.present ? data.device.value : this.device,
      deviceName: data.deviceName.present ? data.deviceName.value : this.deviceName,
      day: data.day.present ? data.day.value : this.day,
      app: data.app.present ? data.app.value : this.app,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      rx: data.rx.present ? data.rx.value : this.rx,
      tx: data.tx.present ? data.tx.value : this.tx,
      fg: data.fg.present ? data.fg.value : this.fg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppUsage(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('device: $device, ')
          ..write('deviceName: $deviceName, ')
          ..write('day: $day, ')
          ..write('app: $app, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('rx: $rx, ')
          ..write('tx: $tx, ')
          ..write('fg: $fg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, device, deviceName, day, app, name, kind, rx, tx, fg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUsage &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.device == this.device &&
          other.deviceName == this.deviceName &&
          other.day == this.day &&
          other.app == this.app &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.rx == this.rx &&
          other.tx == this.tx &&
          other.fg == this.fg);
}

class NirAppsCompanion extends UpdateCompanion<AppUsage> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> device;
  final Value<String> deviceName;
  final Value<String> day;
  final Value<String> app;
  final Value<String> name;
  final Value<String> kind;
  final Value<int> rx;
  final Value<int> tx;
  final Value<int?> fg;
  final Value<int> rowid;
  const NirAppsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.device = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.day = const Value.absent(),
    this.app = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.rx = const Value.absent(),
    this.tx = const Value.absent(),
    this.fg = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NirAppsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String device,
    this.deviceName = const Value.absent(),
    required String day,
    required String app,
    required String name,
    required String kind,
    this.rx = const Value.absent(),
    this.tx = const Value.absent(),
    this.fg = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       device = Value(device),
       day = Value(day),
       app = Value(app),
       name = Value(name),
       kind = Value(kind);
  static Insertable<AppUsage> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? device,
    Expression<String>? deviceName,
    Expression<String>? day,
    Expression<String>? app,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? rx,
    Expression<int>? tx,
    Expression<int>? fg,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (device != null) 'device': device,
      if (deviceName != null) 'device_name': deviceName,
      if (day != null) 'day': day,
      if (app != null) 'app': app,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (rx != null) 'rx': rx,
      if (tx != null) 'tx': tx,
      if (fg != null) 'fg': fg,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NirAppsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? device,
    Value<String>? deviceName,
    Value<String>? day,
    Value<String>? app,
    Value<String>? name,
    Value<String>? kind,
    Value<int>? rx,
    Value<int>? tx,
    Value<int?>? fg,
    Value<int>? rowid,
  }) {
    return NirAppsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      device: device ?? this.device,
      deviceName: deviceName ?? this.deviceName,
      day: day ?? this.day,
      app: app ?? this.app,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      rx: rx ?? this.rx,
      tx: tx ?? this.tx,
      fg: fg ?? this.fg,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (app.present) {
      map['app'] = Variable<String>(app.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rx.present) {
      map['rx'] = Variable<int>(rx.value);
    }
    if (tx.present) {
      map['tx'] = Variable<int>(tx.value);
    }
    if (fg.present) {
      map['fg'] = Variable<int>(fg.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NirAppsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('device: $device, ')
          ..write('deviceName: $deviceName, ')
          ..write('day: $day, ')
          ..write('app: $app, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('rx: $rx, ')
          ..write('tx: $tx, ')
          ..write('fg: $fg, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NirPlansTable extends NirPlans with TableInfo<$NirPlansTable, DataPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NirPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capBytesMeta = const VerificationMeta('capBytes');
  @override
  late final GeneratedColumn<int> capBytes = GeneratedColumn<int>(
    'cap_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleDayMeta = const VerificationMeta('cycleDay');
  @override
  late final GeneratedColumn<int> cycleDay = GeneratedColumn<int>(
    'cycle_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _kindsMeta = const VerificationMeta('kinds');
  @override
  late final GeneratedColumn<String> kinds = GeneratedColumn<String>(
    'kinds',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('all'),
  );
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
    'device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _warnPercentMeta = const VerificationMeta('warnPercent');
  @override
  late final GeneratedColumn<int> warnPercent = GeneratedColumn<int>(
    'warn_percent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(80),
  );
  static const VerificationMeta _createdMeta = const VerificationMeta('created');
  @override
  late final GeneratedColumn<String> created = GeneratedColumn<String>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    name,
    capBytes,
    cycleDay,
    kinds,
    device,
    warnPercent,
    created,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nir_plans';
  @override
  VerificationContext validateIntegrity(Insertable<DataPlan> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cap_bytes')) {
      context.handle(_capBytesMeta, capBytes.isAcceptableOrUnknown(data['cap_bytes']!, _capBytesMeta));
    } else if (isInserting) {
      context.missing(_capBytesMeta);
    }
    if (data.containsKey('cycle_day')) {
      context.handle(_cycleDayMeta, cycleDay.isAcceptableOrUnknown(data['cycle_day']!, _cycleDayMeta));
    }
    if (data.containsKey('kinds')) {
      context.handle(_kindsMeta, kinds.isAcceptableOrUnknown(data['kinds']!, _kindsMeta));
    }
    if (data.containsKey('device')) {
      context.handle(_deviceMeta, device.isAcceptableOrUnknown(data['device']!, _deviceMeta));
    }
    if (data.containsKey('warn_percent')) {
      context.handle(
        _warnPercentMeta,
        warnPercent.isAcceptableOrUnknown(data['warn_percent']!, _warnPercentMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(_createdMeta, created.isAcceptableOrUnknown(data['created']!, _createdMeta));
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DataPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataPlan(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      capBytes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}cap_bytes'])!,
      cycleDay: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}cycle_day'])!,
      kinds: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kinds'])!,
      device: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}device'])!,
      warnPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warn_percent'],
      )!,
      created: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}created'])!,
    );
  }

  @override
  $NirPlansTable createAlias(String alias) {
    return $NirPlansTable(attachedDatabase, alias);
  }
}

class DataPlan extends DataClass implements Insertable<DataPlan> {
  final String id;
  final String hlc;
  final bool deleted;
  final String name;
  final int capBytes;

  /// Day of the month the allowance starts again, 1 to 28.
  final int cycleDay;

  /// Which traffic counts: all | mobile | wifi | ethernet
  final String kinds;

  /// The device it applies to, or '' for every device on the account.
  final String device;

  /// Warn once this share of the allowance is used, 1 to 100.
  final int warnPercent;
  final String created;
  const DataPlan({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.name,
    required this.capBytes,
    required this.cycleDay,
    required this.kinds,
    required this.device,
    required this.warnPercent,
    required this.created,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    map['cap_bytes'] = Variable<int>(capBytes);
    map['cycle_day'] = Variable<int>(cycleDay);
    map['kinds'] = Variable<String>(kinds);
    map['device'] = Variable<String>(device);
    map['warn_percent'] = Variable<int>(warnPercent);
    map['created'] = Variable<String>(created);
    return map;
  }

  NirPlansCompanion toCompanion(bool nullToAbsent) {
    return NirPlansCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      name: Value(name),
      capBytes: Value(capBytes),
      cycleDay: Value(cycleDay),
      kinds: Value(kinds),
      device: Value(device),
      warnPercent: Value(warnPercent),
      created: Value(created),
    );
  }

  factory DataPlan.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataPlan(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      capBytes: serializer.fromJson<int>(json['capBytes']),
      cycleDay: serializer.fromJson<int>(json['cycleDay']),
      kinds: serializer.fromJson<String>(json['kinds']),
      device: serializer.fromJson<String>(json['device']),
      warnPercent: serializer.fromJson<int>(json['warnPercent']),
      created: serializer.fromJson<String>(json['created']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'capBytes': serializer.toJson<int>(capBytes),
      'cycleDay': serializer.toJson<int>(cycleDay),
      'kinds': serializer.toJson<String>(kinds),
      'device': serializer.toJson<String>(device),
      'warnPercent': serializer.toJson<int>(warnPercent),
      'created': serializer.toJson<String>(created),
    };
  }

  DataPlan copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? name,
    int? capBytes,
    int? cycleDay,
    String? kinds,
    String? device,
    int? warnPercent,
    String? created,
  }) => DataPlan(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    name: name ?? this.name,
    capBytes: capBytes ?? this.capBytes,
    cycleDay: cycleDay ?? this.cycleDay,
    kinds: kinds ?? this.kinds,
    device: device ?? this.device,
    warnPercent: warnPercent ?? this.warnPercent,
    created: created ?? this.created,
  );
  DataPlan copyWithCompanion(NirPlansCompanion data) {
    return DataPlan(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      capBytes: data.capBytes.present ? data.capBytes.value : this.capBytes,
      cycleDay: data.cycleDay.present ? data.cycleDay.value : this.cycleDay,
      kinds: data.kinds.present ? data.kinds.value : this.kinds,
      device: data.device.present ? data.device.value : this.device,
      warnPercent: data.warnPercent.present ? data.warnPercent.value : this.warnPercent,
      created: data.created.present ? data.created.value : this.created,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataPlan(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('capBytes: $capBytes, ')
          ..write('cycleDay: $cycleDay, ')
          ..write('kinds: $kinds, ')
          ..write('device: $device, ')
          ..write('warnPercent: $warnPercent, ')
          ..write('created: $created')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deleted, name, capBytes, cycleDay, kinds, device, warnPercent, created);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataPlan &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.capBytes == this.capBytes &&
          other.cycleDay == this.cycleDay &&
          other.kinds == this.kinds &&
          other.device == this.device &&
          other.warnPercent == this.warnPercent &&
          other.created == this.created);
}

class NirPlansCompanion extends UpdateCompanion<DataPlan> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<int> capBytes;
  final Value<int> cycleDay;
  final Value<String> kinds;
  final Value<String> device;
  final Value<int> warnPercent;
  final Value<String> created;
  final Value<int> rowid;
  const NirPlansCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.capBytes = const Value.absent(),
    this.cycleDay = const Value.absent(),
    this.kinds = const Value.absent(),
    this.device = const Value.absent(),
    this.warnPercent = const Value.absent(),
    this.created = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NirPlansCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String name,
    required int capBytes,
    this.cycleDay = const Value.absent(),
    this.kinds = const Value.absent(),
    this.device = const Value.absent(),
    this.warnPercent = const Value.absent(),
    required String created,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       capBytes = Value(capBytes),
       created = Value(created);
  static Insertable<DataPlan> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<int>? capBytes,
    Expression<int>? cycleDay,
    Expression<String>? kinds,
    Expression<String>? device,
    Expression<int>? warnPercent,
    Expression<String>? created,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (capBytes != null) 'cap_bytes': capBytes,
      if (cycleDay != null) 'cycle_day': cycleDay,
      if (kinds != null) 'kinds': kinds,
      if (device != null) 'device': device,
      if (warnPercent != null) 'warn_percent': warnPercent,
      if (created != null) 'created': created,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NirPlansCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? name,
    Value<int>? capBytes,
    Value<int>? cycleDay,
    Value<String>? kinds,
    Value<String>? device,
    Value<int>? warnPercent,
    Value<String>? created,
    Value<int>? rowid,
  }) {
    return NirPlansCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      capBytes: capBytes ?? this.capBytes,
      cycleDay: cycleDay ?? this.cycleDay,
      kinds: kinds ?? this.kinds,
      device: device ?? this.device,
      warnPercent: warnPercent ?? this.warnPercent,
      created: created ?? this.created,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (capBytes.present) {
      map['cap_bytes'] = Variable<int>(capBytes.value);
    }
    if (cycleDay.present) {
      map['cycle_day'] = Variable<int>(cycleDay.value);
    }
    if (kinds.present) {
      map['kinds'] = Variable<String>(kinds.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (warnPercent.present) {
      map['warn_percent'] = Variable<int>(warnPercent.value);
    }
    if (created.present) {
      map['created'] = Variable<String>(created.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NirPlansCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('capBytes: $capBytes, ')
          ..write('cycleDay: $cycleDay, ')
          ..write('kinds: $kinds, ')
          ..write('device: $device, ')
          ..write('warnPercent: $warnPercent, ')
          ..write('created: $created, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NirSpeedTestsTable extends NirSpeedTests with TableInfo<$NirSpeedTestsTable, SpeedTest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NirSpeedTestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
    'device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta('deviceName');
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downMeta = const VerificationMeta('down');
  @override
  late final GeneratedColumn<int> down = GeneratedColumn<int>(
    'down',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _upMeta = const VerificationMeta('up');
  @override
  late final GeneratedColumn<int> up = GeneratedColumn<int>(
    'up',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latencyMeta = const VerificationMeta('latency');
  @override
  late final GeneratedColumn<double> latency = GeneratedColumn<double>(
    'latency',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jitterMeta = const VerificationMeta('jitter');
  @override
  late final GeneratedColumn<double> jitter = GeneratedColumn<double>(
    'jitter',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<String> server = GeneratedColumn<String>(
    'server',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    device,
    deviceName,
    at,
    down,
    up,
    latency,
    jitter,
    kind,
    server,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nir_speed_tests';
  @override
  VerificationContext validateIntegrity(Insertable<SpeedTest> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('device')) {
      context.handle(_deviceMeta, device.isAcceptableOrUnknown(data['device']!, _deviceMeta));
    } else if (isInserting) {
      context.missing(_deviceMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('down')) {
      context.handle(_downMeta, down.isAcceptableOrUnknown(data['down']!, _downMeta));
    } else if (isInserting) {
      context.missing(_downMeta);
    }
    if (data.containsKey('up')) {
      context.handle(_upMeta, up.isAcceptableOrUnknown(data['up']!, _upMeta));
    } else if (isInserting) {
      context.missing(_upMeta);
    }
    if (data.containsKey('latency')) {
      context.handle(_latencyMeta, latency.isAcceptableOrUnknown(data['latency']!, _latencyMeta));
    } else if (isInserting) {
      context.missing(_latencyMeta);
    }
    if (data.containsKey('jitter')) {
      context.handle(_jitterMeta, jitter.isAcceptableOrUnknown(data['jitter']!, _jitterMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('server')) {
      context.handle(_serverMeta, server.isAcceptableOrUnknown(data['server']!, _serverMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpeedTest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpeedTest(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      device: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}device'])!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}at'])!,
      down: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}down'])!,
      up: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}up'])!,
      latency: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}latency'])!,
      jitter: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}jitter'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      server: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}server'])!,
    );
  }

  @override
  $NirSpeedTestsTable createAlias(String alias) {
    return $NirSpeedTestsTable(attachedDatabase, alias);
  }
}

class SpeedTest extends DataClass implements Insertable<SpeedTest> {
  final String id;
  final String hlc;
  final bool deleted;
  final String device;
  final String deviceName;

  /// When it ran, ISO 8601 UTC.
  final String at;

  /// Bits per second.
  final int down;
  final int up;

  /// Round trip and its spread, in milliseconds.
  final double latency;
  final double jitter;

  /// What the device was on: wifi | ethernet | mobile | other
  final String kind;
  final String server;
  const SpeedTest({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.device,
    required this.deviceName,
    required this.at,
    required this.down,
    required this.up,
    required this.latency,
    required this.jitter,
    required this.kind,
    required this.server,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['device'] = Variable<String>(device);
    map['device_name'] = Variable<String>(deviceName);
    map['at'] = Variable<String>(at);
    map['down'] = Variable<int>(down);
    map['up'] = Variable<int>(up);
    map['latency'] = Variable<double>(latency);
    map['jitter'] = Variable<double>(jitter);
    map['kind'] = Variable<String>(kind);
    map['server'] = Variable<String>(server);
    return map;
  }

  NirSpeedTestsCompanion toCompanion(bool nullToAbsent) {
    return NirSpeedTestsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      device: Value(device),
      deviceName: Value(deviceName),
      at: Value(at),
      down: Value(down),
      up: Value(up),
      latency: Value(latency),
      jitter: Value(jitter),
      kind: Value(kind),
      server: Value(server),
    );
  }

  factory SpeedTest.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpeedTest(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      device: serializer.fromJson<String>(json['device']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      at: serializer.fromJson<String>(json['at']),
      down: serializer.fromJson<int>(json['down']),
      up: serializer.fromJson<int>(json['up']),
      latency: serializer.fromJson<double>(json['latency']),
      jitter: serializer.fromJson<double>(json['jitter']),
      kind: serializer.fromJson<String>(json['kind']),
      server: serializer.fromJson<String>(json['server']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'device': serializer.toJson<String>(device),
      'deviceName': serializer.toJson<String>(deviceName),
      'at': serializer.toJson<String>(at),
      'down': serializer.toJson<int>(down),
      'up': serializer.toJson<int>(up),
      'latency': serializer.toJson<double>(latency),
      'jitter': serializer.toJson<double>(jitter),
      'kind': serializer.toJson<String>(kind),
      'server': serializer.toJson<String>(server),
    };
  }

  SpeedTest copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? device,
    String? deviceName,
    String? at,
    int? down,
    int? up,
    double? latency,
    double? jitter,
    String? kind,
    String? server,
  }) => SpeedTest(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    device: device ?? this.device,
    deviceName: deviceName ?? this.deviceName,
    at: at ?? this.at,
    down: down ?? this.down,
    up: up ?? this.up,
    latency: latency ?? this.latency,
    jitter: jitter ?? this.jitter,
    kind: kind ?? this.kind,
    server: server ?? this.server,
  );
  SpeedTest copyWithCompanion(NirSpeedTestsCompanion data) {
    return SpeedTest(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      device: data.device.present ? data.device.value : this.device,
      deviceName: data.deviceName.present ? data.deviceName.value : this.deviceName,
      at: data.at.present ? data.at.value : this.at,
      down: data.down.present ? data.down.value : this.down,
      up: data.up.present ? data.up.value : this.up,
      latency: data.latency.present ? data.latency.value : this.latency,
      jitter: data.jitter.present ? data.jitter.value : this.jitter,
      kind: data.kind.present ? data.kind.value : this.kind,
      server: data.server.present ? data.server.value : this.server,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpeedTest(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('device: $device, ')
          ..write('deviceName: $deviceName, ')
          ..write('at: $at, ')
          ..write('down: $down, ')
          ..write('up: $up, ')
          ..write('latency: $latency, ')
          ..write('jitter: $jitter, ')
          ..write('kind: $kind, ')
          ..write('server: $server')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deleted, device, deviceName, at, down, up, latency, jitter, kind, server);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeedTest &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.device == this.device &&
          other.deviceName == this.deviceName &&
          other.at == this.at &&
          other.down == this.down &&
          other.up == this.up &&
          other.latency == this.latency &&
          other.jitter == this.jitter &&
          other.kind == this.kind &&
          other.server == this.server);
}

class NirSpeedTestsCompanion extends UpdateCompanion<SpeedTest> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> device;
  final Value<String> deviceName;
  final Value<String> at;
  final Value<int> down;
  final Value<int> up;
  final Value<double> latency;
  final Value<double> jitter;
  final Value<String> kind;
  final Value<String> server;
  final Value<int> rowid;
  const NirSpeedTestsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.device = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.at = const Value.absent(),
    this.down = const Value.absent(),
    this.up = const Value.absent(),
    this.latency = const Value.absent(),
    this.jitter = const Value.absent(),
    this.kind = const Value.absent(),
    this.server = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NirSpeedTestsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String device,
    this.deviceName = const Value.absent(),
    required String at,
    required int down,
    required int up,
    required double latency,
    this.jitter = const Value.absent(),
    this.kind = const Value.absent(),
    this.server = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       device = Value(device),
       at = Value(at),
       down = Value(down),
       up = Value(up),
       latency = Value(latency);
  static Insertable<SpeedTest> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? device,
    Expression<String>? deviceName,
    Expression<String>? at,
    Expression<int>? down,
    Expression<int>? up,
    Expression<double>? latency,
    Expression<double>? jitter,
    Expression<String>? kind,
    Expression<String>? server,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (device != null) 'device': device,
      if (deviceName != null) 'device_name': deviceName,
      if (at != null) 'at': at,
      if (down != null) 'down': down,
      if (up != null) 'up': up,
      if (latency != null) 'latency': latency,
      if (jitter != null) 'jitter': jitter,
      if (kind != null) 'kind': kind,
      if (server != null) 'server': server,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NirSpeedTestsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? device,
    Value<String>? deviceName,
    Value<String>? at,
    Value<int>? down,
    Value<int>? up,
    Value<double>? latency,
    Value<double>? jitter,
    Value<String>? kind,
    Value<String>? server,
    Value<int>? rowid,
  }) {
    return NirSpeedTestsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      device: device ?? this.device,
      deviceName: deviceName ?? this.deviceName,
      at: at ?? this.at,
      down: down ?? this.down,
      up: up ?? this.up,
      latency: latency ?? this.latency,
      jitter: jitter ?? this.jitter,
      kind: kind ?? this.kind,
      server: server ?? this.server,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (down.present) {
      map['down'] = Variable<int>(down.value);
    }
    if (up.present) {
      map['up'] = Variable<int>(up.value);
    }
    if (latency.present) {
      map['latency'] = Variable<double>(latency.value);
    }
    if (jitter.present) {
      map['jitter'] = Variable<double>(jitter.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (server.present) {
      map['server'] = Variable<String>(server.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NirSpeedTestsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('device: $device, ')
          ..write('deviceName: $deviceName, ')
          ..write('at: $at, ')
          ..write('down: $down, ')
          ..write('up: $up, ')
          ..write('latency: $latency, ')
          ..write('jitter: $jitter, ')
          ..write('kind: $kind, ')
          ..write('server: $server, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NirThemesTable extends NirThemes with TableInfo<$NirThemesTable, ThemeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NirThemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta('updated');
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, hlc, deleted, name, json, updated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nir_themes';
  @override
  VerificationContext validateIntegrity(Insertable<ThemeRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('json')) {
      context.handle(_jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(_updatedMeta, updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta));
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ThemeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThemeRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      json: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      updated: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated'])!,
    );
  }

  @override
  $NirThemesTable createAlias(String alias) {
    return $NirThemesTable(attachedDatabase, alias);
  }
}

class ThemeRow extends DataClass implements Insertable<ThemeRow> {
  final String id;
  final String hlc;
  final bool deleted;
  final String name;
  final String json;
  final String updated;
  const ThemeRow({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.name,
    required this.json,
    required this.updated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    map['json'] = Variable<String>(json);
    map['updated'] = Variable<String>(updated);
    return map;
  }

  NirThemesCompanion toCompanion(bool nullToAbsent) {
    return NirThemesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      name: Value(name),
      json: Value(json),
      updated: Value(updated),
    );
  }

  factory ThemeRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThemeRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      json: serializer.fromJson<String>(json['json']),
      updated: serializer.fromJson<String>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'json': serializer.toJson<String>(json),
      'updated': serializer.toJson<String>(updated),
    };
  }

  ThemeRow copyWith({String? id, String? hlc, bool? deleted, String? name, String? json, String? updated}) =>
      ThemeRow(
        id: id ?? this.id,
        hlc: hlc ?? this.hlc,
        deleted: deleted ?? this.deleted,
        name: name ?? this.name,
        json: json ?? this.json,
        updated: updated ?? this.updated,
      );
  ThemeRow copyWithCompanion(NirThemesCompanion data) {
    return ThemeRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      json: data.json.present ? data.json.value : this.json,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThemeRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('json: $json, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, name, json, updated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThemeRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.json == this.json &&
          other.updated == this.updated);
}

class NirThemesCompanion extends UpdateCompanion<ThemeRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<String> json;
  final Value<String> updated;
  final Value<int> rowid;
  const NirThemesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.json = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NirThemesCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String name,
    required String json,
    required String updated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       json = Value(json),
       updated = Value(updated);
  static Insertable<ThemeRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<String>? json,
    Expression<String>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (json != null) 'json': json,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NirThemesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? name,
    Value<String>? json,
    Value<String>? updated,
    Value<int>? rowid,
  }) {
    return NirThemesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      json: json ?? this.json,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NirThemesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('json: $json, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrefsTable extends Prefs with TableInfo<$PrefsTable, Pref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
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
  List<GeneratedColumn> get $columns => [id, hlc, deleted, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefs';
  @override
  VerificationContext validateIntegrity(Insertable<Pref> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pref(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $PrefsTable createAlias(String alias) {
    return $PrefsTable(attachedDatabase, alias);
  }
}

class Pref extends DataClass implements Insertable<Pref> {
  final String id;
  final String hlc;
  final bool deleted;
  final String value;
  const Pref({required this.id, required this.hlc, required this.deleted, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['value'] = Variable<String>(value);
    return map;
  }

  PrefsCompanion toCompanion(bool nullToAbsent) {
    return PrefsCompanion(id: Value(id), hlc: Value(hlc), deleted: Value(deleted), value: Value(value));
  }

  factory Pref.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pref(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'value': serializer.toJson<String>(value),
    };
  }

  Pref copyWith({String? id, String? hlc, bool? deleted, String? value}) => Pref(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    value: value ?? this.value,
  );
  Pref copyWithCompanion(PrefsCompanion data) {
    return Pref(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pref(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pref &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.value == this.value);
}

class PrefsCompanion extends UpdateCompanion<Pref> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> value;
  final Value<int> rowid;
  const PrefsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrefsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String value,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       value = Value(value);
  static Insertable<Pref> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrefsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PrefsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
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
    return (StringBuffer('PrefsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [entity, rowId, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxItem> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(_entityMeta, entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(_rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(_seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, rowId};
  @override
  OutboxItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxItem(
      entity: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      rowId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}row_id'])!,
      seq: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}seq']),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxItem extends DataClass implements Insertable<OutboxItem> {
  final String entity;
  final String rowId;
  final int? seq;
  const OutboxItem({required this.entity, required this.rowId, this.seq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['row_id'] = Variable<String>(rowId);
    if (!nullToAbsent || seq != null) {
      map['seq'] = Variable<int>(seq);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      entity: Value(entity),
      rowId: Value(rowId),
      seq: seq == null && nullToAbsent ? const Value.absent() : Value(seq),
    );
  }

  factory OutboxItem.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxItem(
      entity: serializer.fromJson<String>(json['entity']),
      rowId: serializer.fromJson<String>(json['rowId']),
      seq: serializer.fromJson<int?>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'rowId': serializer.toJson<String>(rowId),
      'seq': serializer.toJson<int?>(seq),
    };
  }

  OutboxItem copyWith({String? entity, String? rowId, Value<int?> seq = const Value.absent()}) => OutboxItem(
    entity: entity ?? this.entity,
    rowId: rowId ?? this.rowId,
    seq: seq.present ? seq.value : this.seq,
  );
  OutboxItem copyWithCompanion(OutboxCompanion data) {
    return OutboxItem(
      entity: data.entity.present ? data.entity.value : this.entity,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxItem(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, rowId, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxItem &&
          other.entity == this.entity &&
          other.rowId == this.rowId &&
          other.seq == this.seq);
}

class OutboxCompanion extends UpdateCompanion<OutboxItem> {
  final Value<String> entity;
  final Value<String> rowId;
  final Value<int?> seq;
  final Value<int> rowid;
  const OutboxCompanion({
    this.entity = const Value.absent(),
    this.rowId = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String entity,
    required String rowId,
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       rowId = Value(rowId);
  static Insertable<OutboxItem> custom({
    Expression<String>? entity,
    Expression<String>? rowId,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (rowId != null) 'row_id': rowId,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? entity,
    Value<String>? rowId,
    Value<int?>? seq,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      entity: entity ?? this.entity,
      rowId: rowId ?? this.rowId,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(Insertable<SyncCursor> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta, deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(_seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      deviceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      seq: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String deviceId;
  final int seq;
  const SyncCursor({required this.deviceId, required this.seq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['seq'] = Variable<int>(seq);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(deviceId: Value(deviceId), seq: Value(seq));
  }

  factory SyncCursor.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'seq': serializer.toJson<int>(seq),
    };
  }

  SyncCursor copyWith({String? deviceId, int? seq}) =>
      SyncCursor(deviceId: deviceId ?? this.deviceId, seq: seq ?? this.seq);
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('deviceId: $deviceId, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor && other.deviceId == this.deviceId && other.seq == this.seq);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> deviceId;
  final Value<int> seq;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.deviceId = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({required String deviceId, required int seq, this.rowid = const Value.absent()})
    : deviceId = Value(deviceId),
      seq = Value(seq);
  static Insertable<SyncCursor> custom({
    Expression<String>? deviceId,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({Value<String>? deviceId, Value<int>? seq, Value<int>? rowid}) {
    return SyncCursorsCompanion(
      deviceId: deviceId ?? this.deviceId,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSetting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String key;
  final String value;
  const LocalSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory LocalSetting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
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

  LocalSetting copyWith({String? key, String? value}) =>
      LocalSetting(key: key ?? this.key, value: value ?? this.value);
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LocalSetting && other.key == this.key && other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalSetting> custom({
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

  LocalSettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return LocalSettingsCompanion(
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
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NirDaysTable nirDays = $NirDaysTable(this);
  late final $NirAppsTable nirApps = $NirAppsTable(this);
  late final $NirPlansTable nirPlans = $NirPlansTable(this);
  late final $NirSpeedTestsTable nirSpeedTests = $NirSpeedTestsTable(this);
  late final $NirThemesTable nirThemes = $NirThemesTable(this);
  late final $PrefsTable prefs = $PrefsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    nirDays,
    nirApps,
    nirPlans,
    nirSpeedTests,
    nirThemes,
    prefs,
    outbox,
    syncCursors,
    localSettings,
  ];
}

typedef $$NirDaysTableCreateCompanionBuilder = NirDaysCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String device,
  Value<String> deviceName,
  required String day,
  required String kind,
  Value<int> rx,
  Value<int> tx,
  Value<String> source,
  Value<int> rowid,
});
typedef $$NirDaysTableUpdateCompanionBuilder = NirDaysCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> device,
  Value<String> deviceName,
  Value<String> day,
  Value<String> kind,
  Value<int> rx,
  Value<int> tx,
  Value<String> source,
  Value<int> rowid,
});

class $$NirDaysTableFilterComposer extends Composer<_$AppDatabase, $NirDaysTable> {
  $$NirDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceName =>
      $composableBuilder(column: $table.deviceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rx =>
      $composableBuilder(column: $table.rx, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tx =>
      $composableBuilder(column: $table.tx, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnFilters(column));
}

class $$NirDaysTableOrderingComposer extends Composer<_$AppDatabase, $NirDaysTable> {
  $$NirDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceName =>
      $composableBuilder(column: $table.deviceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rx =>
      $composableBuilder(column: $table.rx, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tx =>
      $composableBuilder(column: $table.tx, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnOrderings(column));
}

class $$NirDaysTableAnnotationComposer extends Composer<_$AppDatabase, $NirDaysTable> {
  $$NirDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => column);

  GeneratedColumn<String> get deviceName =>
      $composableBuilder(column: $table.deviceName, builder: (column) => column);

  GeneratedColumn<String> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get rx => $composableBuilder(column: $table.rx, builder: (column) => column);

  GeneratedColumn<int> get tx => $composableBuilder(column: $table.tx, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$NirDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NirDaysTable,
          DayUsage,
          $$NirDaysTableFilterComposer,
          $$NirDaysTableOrderingComposer,
          $$NirDaysTableAnnotationComposer,
          $$NirDaysTableCreateCompanionBuilder,
          $$NirDaysTableUpdateCompanionBuilder,
          (DayUsage, BaseReferences<_$AppDatabase, $NirDaysTable, DayUsage>),
          DayUsage,
          PrefetchHooks Function()
        > {
  $$NirDaysTableTableManager(_$AppDatabase db, $NirDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$NirDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$NirDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$NirDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> device = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rx = const Value.absent(),
                Value<int> tx = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NirDaysCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                device: device,
                deviceName: deviceName,
                day: day,
                kind: kind,
                rx: rx,
                tx: tx,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String device,
                Value<String> deviceName = const Value.absent(),
                required String day,
                required String kind,
                Value<int> rx = const Value.absent(),
                Value<int> tx = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NirDaysCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                device: device,
                deviceName: deviceName,
                day: day,
                kind: kind,
                rx: rx,
                tx: tx,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NirDaysTable, DayUsage>(table),
                  BaseReferences<_$AppDatabase, $NirDaysTable, DayUsage>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NirDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NirDaysTable,
      DayUsage,
      $$NirDaysTableFilterComposer,
      $$NirDaysTableOrderingComposer,
      $$NirDaysTableAnnotationComposer,
      $$NirDaysTableCreateCompanionBuilder,
      $$NirDaysTableUpdateCompanionBuilder,
      (DayUsage, BaseReferences<_$AppDatabase, $NirDaysTable, DayUsage>),
      DayUsage,
      PrefetchHooks Function()
    >;
typedef $$NirAppsTableCreateCompanionBuilder = NirAppsCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String device,
  Value<String> deviceName,
  required String day,
  required String app,
  required String name,
  required String kind,
  Value<int> rx,
  Value<int> tx,
  Value<int?> fg,
  Value<int> rowid,
});
typedef $$NirAppsTableUpdateCompanionBuilder = NirAppsCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> device,
  Value<String> deviceName,
  Value<String> day,
  Value<String> app,
  Value<String> name,
  Value<String> kind,
  Value<int> rx,
  Value<int> tx,
  Value<int?> fg,
  Value<int> rowid,
});

class $$NirAppsTableFilterComposer extends Composer<_$AppDatabase, $NirAppsTable> {
  $$NirAppsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceName =>
      $composableBuilder(column: $table.deviceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get app =>
      $composableBuilder(column: $table.app, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rx =>
      $composableBuilder(column: $table.rx, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tx =>
      $composableBuilder(column: $table.tx, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fg =>
      $composableBuilder(column: $table.fg, builder: (column) => ColumnFilters(column));
}

class $$NirAppsTableOrderingComposer extends Composer<_$AppDatabase, $NirAppsTable> {
  $$NirAppsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceName =>
      $composableBuilder(column: $table.deviceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get app =>
      $composableBuilder(column: $table.app, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rx =>
      $composableBuilder(column: $table.rx, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tx =>
      $composableBuilder(column: $table.tx, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fg =>
      $composableBuilder(column: $table.fg, builder: (column) => ColumnOrderings(column));
}

class $$NirAppsTableAnnotationComposer extends Composer<_$AppDatabase, $NirAppsTable> {
  $$NirAppsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => column);

  GeneratedColumn<String> get deviceName =>
      $composableBuilder(column: $table.deviceName, builder: (column) => column);

  GeneratedColumn<String> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get app => $composableBuilder(column: $table.app, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get rx => $composableBuilder(column: $table.rx, builder: (column) => column);

  GeneratedColumn<int> get tx => $composableBuilder(column: $table.tx, builder: (column) => column);

  GeneratedColumn<int> get fg => $composableBuilder(column: $table.fg, builder: (column) => column);
}

class $$NirAppsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NirAppsTable,
          AppUsage,
          $$NirAppsTableFilterComposer,
          $$NirAppsTableOrderingComposer,
          $$NirAppsTableAnnotationComposer,
          $$NirAppsTableCreateCompanionBuilder,
          $$NirAppsTableUpdateCompanionBuilder,
          (AppUsage, BaseReferences<_$AppDatabase, $NirAppsTable, AppUsage>),
          AppUsage,
          PrefetchHooks Function()
        > {
  $$NirAppsTableTableManager(_$AppDatabase db, $NirAppsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$NirAppsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$NirAppsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$NirAppsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> device = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> app = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rx = const Value.absent(),
                Value<int> tx = const Value.absent(),
                Value<int?> fg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NirAppsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                device: device,
                deviceName: deviceName,
                day: day,
                app: app,
                name: name,
                kind: kind,
                rx: rx,
                tx: tx,
                fg: fg,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String device,
                Value<String> deviceName = const Value.absent(),
                required String day,
                required String app,
                required String name,
                required String kind,
                Value<int> rx = const Value.absent(),
                Value<int> tx = const Value.absent(),
                Value<int?> fg = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NirAppsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                device: device,
                deviceName: deviceName,
                day: day,
                app: app,
                name: name,
                kind: kind,
                rx: rx,
                tx: tx,
                fg: fg,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NirAppsTable, AppUsage>(table),
                  BaseReferences<_$AppDatabase, $NirAppsTable, AppUsage>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NirAppsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NirAppsTable,
      AppUsage,
      $$NirAppsTableFilterComposer,
      $$NirAppsTableOrderingComposer,
      $$NirAppsTableAnnotationComposer,
      $$NirAppsTableCreateCompanionBuilder,
      $$NirAppsTableUpdateCompanionBuilder,
      (AppUsage, BaseReferences<_$AppDatabase, $NirAppsTable, AppUsage>),
      AppUsage,
      PrefetchHooks Function()
    >;
typedef $$NirPlansTableCreateCompanionBuilder = NirPlansCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String name,
  required int capBytes,
  Value<int> cycleDay,
  Value<String> kinds,
  Value<String> device,
  Value<int> warnPercent,
  required String created,
  Value<int> rowid,
});
typedef $$NirPlansTableUpdateCompanionBuilder = NirPlansCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> name,
  Value<int> capBytes,
  Value<int> cycleDay,
  Value<String> kinds,
  Value<String> device,
  Value<int> warnPercent,
  Value<String> created,
  Value<int> rowid,
});

class $$NirPlansTableFilterComposer extends Composer<_$AppDatabase, $NirPlansTable> {
  $$NirPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get capBytes =>
      $composableBuilder(column: $table.capBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cycleDay =>
      $composableBuilder(column: $table.cycleDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kinds =>
      $composableBuilder(column: $table.kinds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get warnPercent =>
      $composableBuilder(column: $table.warnPercent, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get created =>
      $composableBuilder(column: $table.created, builder: (column) => ColumnFilters(column));
}

class $$NirPlansTableOrderingComposer extends Composer<_$AppDatabase, $NirPlansTable> {
  $$NirPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capBytes =>
      $composableBuilder(column: $table.capBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cycleDay =>
      $composableBuilder(column: $table.cycleDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kinds =>
      $composableBuilder(column: $table.kinds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get warnPercent =>
      $composableBuilder(column: $table.warnPercent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get created =>
      $composableBuilder(column: $table.created, builder: (column) => ColumnOrderings(column));
}

class $$NirPlansTableAnnotationComposer extends Composer<_$AppDatabase, $NirPlansTable> {
  $$NirPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get capBytes =>
      $composableBuilder(column: $table.capBytes, builder: (column) => column);

  GeneratedColumn<int> get cycleDay =>
      $composableBuilder(column: $table.cycleDay, builder: (column) => column);

  GeneratedColumn<String> get kinds => $composableBuilder(column: $table.kinds, builder: (column) => column);

  GeneratedColumn<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => column);

  GeneratedColumn<int> get warnPercent =>
      $composableBuilder(column: $table.warnPercent, builder: (column) => column);

  GeneratedColumn<String> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);
}

class $$NirPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NirPlansTable,
          DataPlan,
          $$NirPlansTableFilterComposer,
          $$NirPlansTableOrderingComposer,
          $$NirPlansTableAnnotationComposer,
          $$NirPlansTableCreateCompanionBuilder,
          $$NirPlansTableUpdateCompanionBuilder,
          (DataPlan, BaseReferences<_$AppDatabase, $NirPlansTable, DataPlan>),
          DataPlan,
          PrefetchHooks Function()
        > {
  $$NirPlansTableTableManager(_$AppDatabase db, $NirPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$NirPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$NirPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$NirPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> capBytes = const Value.absent(),
                Value<int> cycleDay = const Value.absent(),
                Value<String> kinds = const Value.absent(),
                Value<String> device = const Value.absent(),
                Value<int> warnPercent = const Value.absent(),
                Value<String> created = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NirPlansCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                capBytes: capBytes,
                cycleDay: cycleDay,
                kinds: kinds,
                device: device,
                warnPercent: warnPercent,
                created: created,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String name,
                required int capBytes,
                Value<int> cycleDay = const Value.absent(),
                Value<String> kinds = const Value.absent(),
                Value<String> device = const Value.absent(),
                Value<int> warnPercent = const Value.absent(),
                required String created,
                Value<int> rowid = const Value.absent(),
              }) => NirPlansCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                capBytes: capBytes,
                cycleDay: cycleDay,
                kinds: kinds,
                device: device,
                warnPercent: warnPercent,
                created: created,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NirPlansTable, DataPlan>(table),
                  BaseReferences<_$AppDatabase, $NirPlansTable, DataPlan>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NirPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NirPlansTable,
      DataPlan,
      $$NirPlansTableFilterComposer,
      $$NirPlansTableOrderingComposer,
      $$NirPlansTableAnnotationComposer,
      $$NirPlansTableCreateCompanionBuilder,
      $$NirPlansTableUpdateCompanionBuilder,
      (DataPlan, BaseReferences<_$AppDatabase, $NirPlansTable, DataPlan>),
      DataPlan,
      PrefetchHooks Function()
    >;
typedef $$NirSpeedTestsTableCreateCompanionBuilder = NirSpeedTestsCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String device,
  Value<String> deviceName,
  required String at,
  required int down,
  required int up,
  required double latency,
  Value<double> jitter,
  Value<String> kind,
  Value<String> server,
  Value<int> rowid,
});
typedef $$NirSpeedTestsTableUpdateCompanionBuilder = NirSpeedTestsCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> device,
  Value<String> deviceName,
  Value<String> at,
  Value<int> down,
  Value<int> up,
  Value<double> latency,
  Value<double> jitter,
  Value<String> kind,
  Value<String> server,
  Value<int> rowid,
});

class $$NirSpeedTestsTableFilterComposer extends Composer<_$AppDatabase, $NirSpeedTestsTable> {
  $$NirSpeedTestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceName =>
      $composableBuilder(column: $table.deviceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get down =>
      $composableBuilder(column: $table.down, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get up =>
      $composableBuilder(column: $table.up, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latency =>
      $composableBuilder(column: $table.latency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get jitter =>
      $composableBuilder(column: $table.jitter, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get server =>
      $composableBuilder(column: $table.server, builder: (column) => ColumnFilters(column));
}

class $$NirSpeedTestsTableOrderingComposer extends Composer<_$AppDatabase, $NirSpeedTestsTable> {
  $$NirSpeedTestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceName =>
      $composableBuilder(column: $table.deviceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get down =>
      $composableBuilder(column: $table.down, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get up =>
      $composableBuilder(column: $table.up, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latency =>
      $composableBuilder(column: $table.latency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get jitter =>
      $composableBuilder(column: $table.jitter, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get server =>
      $composableBuilder(column: $table.server, builder: (column) => ColumnOrderings(column));
}

class $$NirSpeedTestsTableAnnotationComposer extends Composer<_$AppDatabase, $NirSpeedTestsTable> {
  $$NirSpeedTestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => column);

  GeneratedColumn<String> get deviceName =>
      $composableBuilder(column: $table.deviceName, builder: (column) => column);

  GeneratedColumn<String> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get down => $composableBuilder(column: $table.down, builder: (column) => column);

  GeneratedColumn<int> get up => $composableBuilder(column: $table.up, builder: (column) => column);

  GeneratedColumn<double> get latency =>
      $composableBuilder(column: $table.latency, builder: (column) => column);

  GeneratedColumn<double> get jitter =>
      $composableBuilder(column: $table.jitter, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get server =>
      $composableBuilder(column: $table.server, builder: (column) => column);
}

class $$NirSpeedTestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NirSpeedTestsTable,
          SpeedTest,
          $$NirSpeedTestsTableFilterComposer,
          $$NirSpeedTestsTableOrderingComposer,
          $$NirSpeedTestsTableAnnotationComposer,
          $$NirSpeedTestsTableCreateCompanionBuilder,
          $$NirSpeedTestsTableUpdateCompanionBuilder,
          (SpeedTest, BaseReferences<_$AppDatabase, $NirSpeedTestsTable, SpeedTest>),
          SpeedTest,
          PrefetchHooks Function()
        > {
  $$NirSpeedTestsTableTableManager(_$AppDatabase db, $NirSpeedTestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$NirSpeedTestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$NirSpeedTestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$NirSpeedTestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> device = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> at = const Value.absent(),
                Value<int> down = const Value.absent(),
                Value<int> up = const Value.absent(),
                Value<double> latency = const Value.absent(),
                Value<double> jitter = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> server = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NirSpeedTestsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                device: device,
                deviceName: deviceName,
                at: at,
                down: down,
                up: up,
                latency: latency,
                jitter: jitter,
                kind: kind,
                server: server,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String device,
                Value<String> deviceName = const Value.absent(),
                required String at,
                required int down,
                required int up,
                required double latency,
                Value<double> jitter = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> server = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NirSpeedTestsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                device: device,
                deviceName: deviceName,
                at: at,
                down: down,
                up: up,
                latency: latency,
                jitter: jitter,
                kind: kind,
                server: server,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NirSpeedTestsTable, SpeedTest>(table),
                  BaseReferences<_$AppDatabase, $NirSpeedTestsTable, SpeedTest>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NirSpeedTestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NirSpeedTestsTable,
      SpeedTest,
      $$NirSpeedTestsTableFilterComposer,
      $$NirSpeedTestsTableOrderingComposer,
      $$NirSpeedTestsTableAnnotationComposer,
      $$NirSpeedTestsTableCreateCompanionBuilder,
      $$NirSpeedTestsTableUpdateCompanionBuilder,
      (SpeedTest, BaseReferences<_$AppDatabase, $NirSpeedTestsTable, SpeedTest>),
      SpeedTest,
      PrefetchHooks Function()
    >;
typedef $$NirThemesTableCreateCompanionBuilder = NirThemesCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String name,
  required String json,
  required String updated,
  Value<int> rowid,
});
typedef $$NirThemesTableUpdateCompanionBuilder = NirThemesCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> name,
  Value<String> json,
  Value<String> updated,
  Value<int> rowid,
});

class $$NirThemesTableFilterComposer extends Composer<_$AppDatabase, $NirThemesTable> {
  $$NirThemesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => ColumnFilters(column));
}

class $$NirThemesTableOrderingComposer extends Composer<_$AppDatabase, $NirThemesTable> {
  $$NirThemesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => ColumnOrderings(column));
}

class $$NirThemesTableAnnotationComposer extends Composer<_$AppDatabase, $NirThemesTable> {
  $$NirThemesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get json => $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);
}

class $$NirThemesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NirThemesTable,
          ThemeRow,
          $$NirThemesTableFilterComposer,
          $$NirThemesTableOrderingComposer,
          $$NirThemesTableAnnotationComposer,
          $$NirThemesTableCreateCompanionBuilder,
          $$NirThemesTableUpdateCompanionBuilder,
          (ThemeRow, BaseReferences<_$AppDatabase, $NirThemesTable, ThemeRow>),
          ThemeRow,
          PrefetchHooks Function()
        > {
  $$NirThemesTableTableManager(_$AppDatabase db, $NirThemesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$NirThemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$NirThemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$NirThemesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NirThemesCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                json: json,
                updated: updated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String name,
                required String json,
                required String updated,
                Value<int> rowid = const Value.absent(),
              }) => NirThemesCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                json: json,
                updated: updated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NirThemesTable, ThemeRow>(table),
                  BaseReferences<_$AppDatabase, $NirThemesTable, ThemeRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NirThemesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NirThemesTable,
      ThemeRow,
      $$NirThemesTableFilterComposer,
      $$NirThemesTableOrderingComposer,
      $$NirThemesTableAnnotationComposer,
      $$NirThemesTableCreateCompanionBuilder,
      $$NirThemesTableUpdateCompanionBuilder,
      (ThemeRow, BaseReferences<_$AppDatabase, $NirThemesTable, ThemeRow>),
      ThemeRow,
      PrefetchHooks Function()
    >;
typedef $$PrefsTableCreateCompanionBuilder = PrefsCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String value,
  Value<int> rowid,
});
typedef $$PrefsTableUpdateCompanionBuilder = PrefsCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> value,
  Value<int> rowid,
});

class $$PrefsTableFilterComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$PrefsTableOrderingComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$PrefsTableAnnotationComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrefsTable,
          Pref,
          $$PrefsTableFilterComposer,
          $$PrefsTableOrderingComposer,
          $$PrefsTableAnnotationComposer,
          $$PrefsTableCreateCompanionBuilder,
          $$PrefsTableUpdateCompanionBuilder,
          (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
          Pref,
          PrefetchHooks Function()
        > {
  $$PrefsTableTableManager(_$AppDatabase db, $PrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> hlc = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion(id: id, hlc: hlc, deleted: deleted, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            Value<String> hlc = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion.insert(id: id, hlc: hlc, deleted: deleted, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrefsTable, Pref>(table),
                  BaseReferences<_$AppDatabase, $PrefsTable, Pref>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrefsTable,
      Pref,
      $$PrefsTableFilterComposer,
      $$PrefsTableOrderingComposer,
      $$PrefsTableAnnotationComposer,
      $$PrefsTableCreateCompanionBuilder,
      $$PrefsTableUpdateCompanionBuilder,
      (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
      Pref,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String entity,
  required String rowId,
  Value<int?> seq,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> entity,
  Value<String> rowId,
  Value<int?> seq,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => ColumnFilters(column));
}

class $$OutboxTableOrderingComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => ColumnOrderings(column));
}

class $$OutboxTableAnnotationComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get rowId => $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<int> get seq => $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxItem,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxItem, BaseReferences<_$AppDatabase, $OutboxTable, OutboxItem>),
          OutboxItem,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entity = const Value.absent(),
            Value<String> rowId = const Value.absent(),
            Value<int?> seq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => OutboxCompanion(entity: entity, rowId: rowId, seq: seq, rowid: rowid),
          createCompanionCallback: ({
            required String entity,
            required String rowId,
            Value<int?> seq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => OutboxCompanion.insert(entity: entity, rowId: rowId, seq: seq, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxItem>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxItem>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxItem,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxItem, BaseReferences<_$AppDatabase, $OutboxTable, OutboxItem>),
      OutboxItem,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder = SyncCursorsCompanion Function({
  required String deviceId,
  required int seq,
  Value<int> rowid,
});
typedef $$SyncCursorsTableUpdateCompanionBuilder = SyncCursorsCompanion Function({
  Value<String> deviceId,
  Value<int> seq,
  Value<int> rowid,
});

class $$SyncCursorsTableFilterComposer extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => ColumnFilters(column));
}

class $$SyncCursorsTableOrderingComposer extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => ColumnOrderings(column));
}

class $$SyncCursorsTableAnnotationComposer extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get seq => $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (SyncCursor, BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deviceId = const Value.absent(),
            Value<int> seq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncCursorsCompanion(deviceId: deviceId, seq: seq, rowid: rowid),
          createCompanionCallback: ({
            required String deviceId,
            required int seq,
            Value<int> rowid = const Value.absent(),
          }) => SyncCursorsCompanion.insert(deviceId: deviceId, seq: seq, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorsTable, SyncCursor>(table),
                  BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (SyncCursor, BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>),
      SyncCursor,
      PrefetchHooks Function()
    >;
typedef $$LocalSettingsTableCreateCompanionBuilder = LocalSettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$LocalSettingsTableUpdateCompanionBuilder = LocalSettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$LocalSettingsTableFilterComposer extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$LocalSettingsTableOrderingComposer extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$LocalSettingsTableAnnotationComposer extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (LocalSetting, BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => LocalSettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSettingsTable, LocalSetting>(table),
                  BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (LocalSetting, BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>),
      LocalSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NirDaysTableTableManager get nirDays => $$NirDaysTableTableManager(_db, _db.nirDays);
  $$NirAppsTableTableManager get nirApps => $$NirAppsTableTableManager(_db, _db.nirApps);
  $$NirPlansTableTableManager get nirPlans => $$NirPlansTableTableManager(_db, _db.nirPlans);
  $$NirSpeedTestsTableTableManager get nirSpeedTests =>
      $$NirSpeedTestsTableTableManager(_db, _db.nirSpeedTests);
  $$NirThemesTableTableManager get nirThemes => $$NirThemesTableTableManager(_db, _db.nirThemes);
  $$PrefsTableTableManager get prefs => $$PrefsTableTableManager(_db, _db.prefs);
  $$OutboxTableTableManager get outbox => $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncCursorsTableTableManager get syncCursors => $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
}
