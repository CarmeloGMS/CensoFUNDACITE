// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedCatalogsTable extends CachedCatalogs
    with TableInfo<$CachedCatalogsTable, CachedCatalog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCatalogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, type, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_catalogs';
  @override
  VerificationContext validateIntegrity(Insertable<CachedCatalog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CachedCatalog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCatalog(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
    );
  }

  @override
  $CachedCatalogsTable createAlias(String alias) {
    return $CachedCatalogsTable(attachedDatabase, alias);
  }
}

class CachedCatalog extends DataClass implements Insertable<CachedCatalog> {
  final String key;
  final String type;
  final String data;
  const CachedCatalog(
      {required this.key, required this.type, required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['type'] = Variable<String>(type);
    map['data'] = Variable<String>(data);
    return map;
  }

  CachedCatalogsCompanion toCompanion(bool nullToAbsent) {
    return CachedCatalogsCompanion(
      key: Value(key),
      type: Value(type),
      data: Value(data),
    );
  }

  factory CachedCatalog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCatalog(
      key: serializer.fromJson<String>(json['key']),
      type: serializer.fromJson<String>(json['type']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'type': serializer.toJson<String>(type),
      'data': serializer.toJson<String>(data),
    };
  }

  CachedCatalog copyWith({String? key, String? type, String? data}) =>
      CachedCatalog(
        key: key ?? this.key,
        type: type ?? this.type,
        data: data ?? this.data,
      );
  CachedCatalog copyWithCompanion(CachedCatalogsCompanion data) {
    return CachedCatalog(
      key: data.key.present ? data.key.value : this.key,
      type: data.type.present ? data.type.value : this.type,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCatalog(')
          ..write('key: $key, ')
          ..write('type: $type, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, type, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCatalog &&
          other.key == this.key &&
          other.type == this.type &&
          other.data == this.data);
}

class CachedCatalogsCompanion extends UpdateCompanion<CachedCatalog> {
  final Value<String> key;
  final Value<String> type;
  final Value<String> data;
  final Value<int> rowid;
  const CachedCatalogsCompanion({
    this.key = const Value.absent(),
    this.type = const Value.absent(),
    this.data = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCatalogsCompanion.insert({
    required String key,
    required String type,
    required String data,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        type = Value(type),
        data = Value(data);
  static Insertable<CachedCatalog> custom({
    Expression<String>? key,
    Expression<String>? type,
    Expression<String>? data,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (type != null) 'type': type,
      if (data != null) 'data': data,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCatalogsCompanion copyWith(
      {Value<String>? key,
      Value<String>? type,
      Value<String>? data,
      Value<int>? rowid}) {
    return CachedCatalogsCompanion(
      key: key ?? this.key,
      type: type ?? this.type,
      data: data ?? this.data,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCatalogsCompanion(')
          ..write('key: $key, ')
          ..write('type: $type, ')
          ..write('data: $data, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalConsejosTable extends LocalConsejos
    with TableInfo<$LocalConsejosTable, ConsejoLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalConsejosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
      'server_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [uuid, serverId, syncState, payload, error, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_consejos';
  @override
  VerificationContext validateIntegrity(Insertable<ConsejoLocal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  ConsejoLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsejoLocal(
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_id']),
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalConsejosTable createAlias(String alias) {
    return $LocalConsejosTable(attachedDatabase, alias);
  }
}

class ConsejoLocal extends DataClass implements Insertable<ConsejoLocal> {
  final String uuid;
  final int? serverId;
  final String syncState;
  final String payload;
  final String? error;
  final int createdAt;
  final int updatedAt;
  const ConsejoLocal(
      {required this.uuid,
      this.serverId,
      required this.syncState,
      required this.payload,
      this.error,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['sync_state'] = Variable<String>(syncState);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LocalConsejosCompanion toCompanion(bool nullToAbsent) {
    return LocalConsejosCompanion(
      uuid: Value(uuid),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      syncState: Value(syncState),
      payload: Value(payload),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConsejoLocal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsejoLocal(
      uuid: serializer.fromJson<String>(json['uuid']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      syncState: serializer.fromJson<String>(json['syncState']),
      payload: serializer.fromJson<String>(json['payload']),
      error: serializer.fromJson<String?>(json['error']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'serverId': serializer.toJson<int?>(serverId),
      'syncState': serializer.toJson<String>(syncState),
      'payload': serializer.toJson<String>(payload),
      'error': serializer.toJson<String?>(error),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ConsejoLocal copyWith(
          {String? uuid,
          Value<int?> serverId = const Value.absent(),
          String? syncState,
          String? payload,
          Value<String?> error = const Value.absent(),
          int? createdAt,
          int? updatedAt}) =>
      ConsejoLocal(
        uuid: uuid ?? this.uuid,
        serverId: serverId.present ? serverId.value : this.serverId,
        syncState: syncState ?? this.syncState,
        payload: payload ?? this.payload,
        error: error.present ? error.value : this.error,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ConsejoLocal copyWithCompanion(LocalConsejosCompanion data) {
    return ConsejoLocal(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      payload: data.payload.present ? data.payload.value : this.payload,
      error: data.error.present ? data.error.value : this.error,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsejoLocal(')
          ..write('uuid: $uuid, ')
          ..write('serverId: $serverId, ')
          ..write('syncState: $syncState, ')
          ..write('payload: $payload, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      uuid, serverId, syncState, payload, error, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsejoLocal &&
          other.uuid == this.uuid &&
          other.serverId == this.serverId &&
          other.syncState == this.syncState &&
          other.payload == this.payload &&
          other.error == this.error &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalConsejosCompanion extends UpdateCompanion<ConsejoLocal> {
  final Value<String> uuid;
  final Value<int?> serverId;
  final Value<String> syncState;
  final Value<String> payload;
  final Value<String?> error;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LocalConsejosCompanion({
    this.uuid = const Value.absent(),
    this.serverId = const Value.absent(),
    this.syncState = const Value.absent(),
    this.payload = const Value.absent(),
    this.error = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalConsejosCompanion.insert({
    required String uuid,
    this.serverId = const Value.absent(),
    this.syncState = const Value.absent(),
    required String payload,
    this.error = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : uuid = Value(uuid),
        payload = Value(payload),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ConsejoLocal> custom({
    Expression<String>? uuid,
    Expression<int>? serverId,
    Expression<String>? syncState,
    Expression<String>? payload,
    Expression<String>? error,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (serverId != null) 'server_id': serverId,
      if (syncState != null) 'sync_state': syncState,
      if (payload != null) 'payload': payload,
      if (error != null) 'error': error,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalConsejosCompanion copyWith(
      {Value<String>? uuid,
      Value<int?>? serverId,
      Value<String>? syncState,
      Value<String>? payload,
      Value<String?>? error,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return LocalConsejosCompanion(
      uuid: uuid ?? this.uuid,
      serverId: serverId ?? this.serverId,
      syncState: syncState ?? this.syncState,
      payload: payload ?? this.payload,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalConsejosCompanion(')
          ..write('uuid: $uuid, ')
          ..write('serverId: $serverId, ')
          ..write('syncState: $syncState, ')
          ..write('payload: $payload, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalFotosTable extends LocalFotos
    with TableInfo<$LocalFotosTable, FotoLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
      'uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _consejoUuidMeta =
      const VerificationMeta('consejoUuid');
  @override
  late final GeneratedColumn<String> consejoUuid = GeneratedColumn<String>(
      'consejo_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descripcionMeta =
      const VerificationMeta('descripcion');
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
      'descripcion', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _uploadedMeta =
      const VerificationMeta('uploaded');
  @override
  late final GeneratedColumn<bool> uploaded = GeneratedColumn<bool>(
      'uploaded', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("uploaded" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
      'error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [uuid, consejoUuid, path, descripcion, uploaded, error];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_fotos';
  @override
  VerificationContext validateIntegrity(Insertable<FotoLocal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
          _uuidMeta, uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta));
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('consejo_uuid')) {
      context.handle(
          _consejoUuidMeta,
          consejoUuid.isAcceptableOrUnknown(
              data['consejo_uuid']!, _consejoUuidMeta));
    } else if (isInserting) {
      context.missing(_consejoUuidMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
          _descripcionMeta,
          descripcion.isAcceptableOrUnknown(
              data['descripcion']!, _descripcionMeta));
    }
    if (data.containsKey('uploaded')) {
      context.handle(_uploadedMeta,
          uploaded.isAcceptableOrUnknown(data['uploaded']!, _uploadedMeta));
    }
    if (data.containsKey('error')) {
      context.handle(
          _errorMeta, error.isAcceptableOrUnknown(data['error']!, _errorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  FotoLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FotoLocal(
      uuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uuid'])!,
      consejoUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}consejo_uuid'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      descripcion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descripcion'])!,
      uploaded: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}uploaded'])!,
      error: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error']),
    );
  }

  @override
  $LocalFotosTable createAlias(String alias) {
    return $LocalFotosTable(attachedDatabase, alias);
  }
}

class FotoLocal extends DataClass implements Insertable<FotoLocal> {
  final String uuid;
  final String consejoUuid;
  final String path;
  final String descripcion;
  final bool uploaded;
  final String? error;
  const FotoLocal(
      {required this.uuid,
      required this.consejoUuid,
      required this.path,
      required this.descripcion,
      required this.uploaded,
      this.error});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['consejo_uuid'] = Variable<String>(consejoUuid);
    map['path'] = Variable<String>(path);
    map['descripcion'] = Variable<String>(descripcion);
    map['uploaded'] = Variable<bool>(uploaded);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  LocalFotosCompanion toCompanion(bool nullToAbsent) {
    return LocalFotosCompanion(
      uuid: Value(uuid),
      consejoUuid: Value(consejoUuid),
      path: Value(path),
      descripcion: Value(descripcion),
      uploaded: Value(uploaded),
      error:
          error == null && nullToAbsent ? const Value.absent() : Value(error),
    );
  }

  factory FotoLocal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FotoLocal(
      uuid: serializer.fromJson<String>(json['uuid']),
      consejoUuid: serializer.fromJson<String>(json['consejoUuid']),
      path: serializer.fromJson<String>(json['path']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      uploaded: serializer.fromJson<bool>(json['uploaded']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'consejoUuid': serializer.toJson<String>(consejoUuid),
      'path': serializer.toJson<String>(path),
      'descripcion': serializer.toJson<String>(descripcion),
      'uploaded': serializer.toJson<bool>(uploaded),
      'error': serializer.toJson<String?>(error),
    };
  }

  FotoLocal copyWith(
          {String? uuid,
          String? consejoUuid,
          String? path,
          String? descripcion,
          bool? uploaded,
          Value<String?> error = const Value.absent()}) =>
      FotoLocal(
        uuid: uuid ?? this.uuid,
        consejoUuid: consejoUuid ?? this.consejoUuid,
        path: path ?? this.path,
        descripcion: descripcion ?? this.descripcion,
        uploaded: uploaded ?? this.uploaded,
        error: error.present ? error.value : this.error,
      );
  FotoLocal copyWithCompanion(LocalFotosCompanion data) {
    return FotoLocal(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      consejoUuid:
          data.consejoUuid.present ? data.consejoUuid.value : this.consejoUuid,
      path: data.path.present ? data.path.value : this.path,
      descripcion:
          data.descripcion.present ? data.descripcion.value : this.descripcion,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FotoLocal(')
          ..write('uuid: $uuid, ')
          ..write('consejoUuid: $consejoUuid, ')
          ..write('path: $path, ')
          ..write('descripcion: $descripcion, ')
          ..write('uploaded: $uploaded, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uuid, consejoUuid, path, descripcion, uploaded, error);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FotoLocal &&
          other.uuid == this.uuid &&
          other.consejoUuid == this.consejoUuid &&
          other.path == this.path &&
          other.descripcion == this.descripcion &&
          other.uploaded == this.uploaded &&
          other.error == this.error);
}

class LocalFotosCompanion extends UpdateCompanion<FotoLocal> {
  final Value<String> uuid;
  final Value<String> consejoUuid;
  final Value<String> path;
  final Value<String> descripcion;
  final Value<bool> uploaded;
  final Value<String?> error;
  final Value<int> rowid;
  const LocalFotosCompanion({
    this.uuid = const Value.absent(),
    this.consejoUuid = const Value.absent(),
    this.path = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFotosCompanion.insert({
    required String uuid,
    required String consejoUuid,
    required String path,
    this.descripcion = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.error = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : uuid = Value(uuid),
        consejoUuid = Value(consejoUuid),
        path = Value(path);
  static Insertable<FotoLocal> custom({
    Expression<String>? uuid,
    Expression<String>? consejoUuid,
    Expression<String>? path,
    Expression<String>? descripcion,
    Expression<bool>? uploaded,
    Expression<String>? error,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (consejoUuid != null) 'consejo_uuid': consejoUuid,
      if (path != null) 'path': path,
      if (descripcion != null) 'descripcion': descripcion,
      if (uploaded != null) 'uploaded': uploaded,
      if (error != null) 'error': error,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFotosCompanion copyWith(
      {Value<String>? uuid,
      Value<String>? consejoUuid,
      Value<String>? path,
      Value<String>? descripcion,
      Value<bool>? uploaded,
      Value<String?>? error,
      Value<int>? rowid}) {
    return LocalFotosCompanion(
      uuid: uuid ?? this.uuid,
      consejoUuid: consejoUuid ?? this.consejoUuid,
      path: path ?? this.path,
      descripcion: descripcion ?? this.descripcion,
      uploaded: uploaded ?? this.uploaded,
      error: error ?? this.error,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (consejoUuid.present) {
      map['consejo_uuid'] = Variable<String>(consejoUuid.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (uploaded.present) {
      map['uploaded'] = Variable<bool>(uploaded.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFotosCompanion(')
          ..write('uuid: $uuid, ')
          ..write('consejoUuid: $consejoUuid, ')
          ..write('path: $path, ')
          ..write('descripcion: $descripcion, ')
          ..write('uploaded: $uploaded, ')
          ..write('error: $error, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedCatalogsTable cachedCatalogs = $CachedCatalogsTable(this);
  late final $LocalConsejosTable localConsejos = $LocalConsejosTable(this);
  late final $LocalFotosTable localFotos = $LocalFotosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cachedCatalogs, localConsejos, localFotos];
}

typedef $$CachedCatalogsTableCreateCompanionBuilder = CachedCatalogsCompanion
    Function({
  required String key,
  required String type,
  required String data,
  Value<int> rowid,
});
typedef $$CachedCatalogsTableUpdateCompanionBuilder = CachedCatalogsCompanion
    Function({
  Value<String> key,
  Value<String> type,
  Value<String> data,
  Value<int> rowid,
});

class $$CachedCatalogsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCatalogsTable> {
  $$CachedCatalogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));
}

class $$CachedCatalogsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCatalogsTable> {
  $$CachedCatalogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));
}

class $$CachedCatalogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCatalogsTable> {
  $$CachedCatalogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$CachedCatalogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedCatalogsTable,
    CachedCatalog,
    $$CachedCatalogsTableFilterComposer,
    $$CachedCatalogsTableOrderingComposer,
    $$CachedCatalogsTableAnnotationComposer,
    $$CachedCatalogsTableCreateCompanionBuilder,
    $$CachedCatalogsTableUpdateCompanionBuilder,
    (
      CachedCatalog,
      BaseReferences<_$AppDatabase, $CachedCatalogsTable, CachedCatalog>
    ),
    CachedCatalog,
    PrefetchHooks Function()> {
  $$CachedCatalogsTableTableManager(
      _$AppDatabase db, $CachedCatalogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCatalogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCatalogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCatalogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedCatalogsCompanion(
            key: key,
            type: type,
            data: data,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String type,
            required String data,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedCatalogsCompanion.insert(
            key: key,
            type: type,
            data: data,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedCatalogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedCatalogsTable,
    CachedCatalog,
    $$CachedCatalogsTableFilterComposer,
    $$CachedCatalogsTableOrderingComposer,
    $$CachedCatalogsTableAnnotationComposer,
    $$CachedCatalogsTableCreateCompanionBuilder,
    $$CachedCatalogsTableUpdateCompanionBuilder,
    (
      CachedCatalog,
      BaseReferences<_$AppDatabase, $CachedCatalogsTable, CachedCatalog>
    ),
    CachedCatalog,
    PrefetchHooks Function()>;
typedef $$LocalConsejosTableCreateCompanionBuilder = LocalConsejosCompanion
    Function({
  required String uuid,
  Value<int?> serverId,
  Value<String> syncState,
  required String payload,
  Value<String?> error,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$LocalConsejosTableUpdateCompanionBuilder = LocalConsejosCompanion
    Function({
  Value<String> uuid,
  Value<int?> serverId,
  Value<String> syncState,
  Value<String> payload,
  Value<String?> error,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$LocalConsejosTableFilterComposer
    extends Composer<_$AppDatabase, $LocalConsejosTable> {
  $$LocalConsejosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalConsejosTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalConsejosTable> {
  $$LocalConsejosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalConsejosTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalConsejosTable> {
  $$LocalConsejosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalConsejosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalConsejosTable,
    ConsejoLocal,
    $$LocalConsejosTableFilterComposer,
    $$LocalConsejosTableOrderingComposer,
    $$LocalConsejosTableAnnotationComposer,
    $$LocalConsejosTableCreateCompanionBuilder,
    $$LocalConsejosTableUpdateCompanionBuilder,
    (
      ConsejoLocal,
      BaseReferences<_$AppDatabase, $LocalConsejosTable, ConsejoLocal>
    ),
    ConsejoLocal,
    PrefetchHooks Function()> {
  $$LocalConsejosTableTableManager(_$AppDatabase db, $LocalConsejosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalConsejosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalConsejosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalConsejosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uuid = const Value.absent(),
            Value<int?> serverId = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalConsejosCompanion(
            uuid: uuid,
            serverId: serverId,
            syncState: syncState,
            payload: payload,
            error: error,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uuid,
            Value<int?> serverId = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            required String payload,
            Value<String?> error = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalConsejosCompanion.insert(
            uuid: uuid,
            serverId: serverId,
            syncState: syncState,
            payload: payload,
            error: error,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalConsejosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalConsejosTable,
    ConsejoLocal,
    $$LocalConsejosTableFilterComposer,
    $$LocalConsejosTableOrderingComposer,
    $$LocalConsejosTableAnnotationComposer,
    $$LocalConsejosTableCreateCompanionBuilder,
    $$LocalConsejosTableUpdateCompanionBuilder,
    (
      ConsejoLocal,
      BaseReferences<_$AppDatabase, $LocalConsejosTable, ConsejoLocal>
    ),
    ConsejoLocal,
    PrefetchHooks Function()>;
typedef $$LocalFotosTableCreateCompanionBuilder = LocalFotosCompanion Function({
  required String uuid,
  required String consejoUuid,
  required String path,
  Value<String> descripcion,
  Value<bool> uploaded,
  Value<String?> error,
  Value<int> rowid,
});
typedef $$LocalFotosTableUpdateCompanionBuilder = LocalFotosCompanion Function({
  Value<String> uuid,
  Value<String> consejoUuid,
  Value<String> path,
  Value<String> descripcion,
  Value<bool> uploaded,
  Value<String?> error,
  Value<int> rowid,
});

class $$LocalFotosTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFotosTable> {
  $$LocalFotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get consejoUuid => $composableBuilder(
      column: $table.consejoUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get uploaded => $composableBuilder(
      column: $table.uploaded, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnFilters(column));
}

class $$LocalFotosTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFotosTable> {
  $$LocalFotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
      column: $table.uuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get consejoUuid => $composableBuilder(
      column: $table.consejoUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get uploaded => $composableBuilder(
      column: $table.uploaded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get error => $composableBuilder(
      column: $table.error, builder: (column) => ColumnOrderings(column));
}

class $$LocalFotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFotosTable> {
  $$LocalFotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get consejoUuid => $composableBuilder(
      column: $table.consejoUuid, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
      column: $table.descripcion, builder: (column) => column);

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);
}

class $$LocalFotosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalFotosTable,
    FotoLocal,
    $$LocalFotosTableFilterComposer,
    $$LocalFotosTableOrderingComposer,
    $$LocalFotosTableAnnotationComposer,
    $$LocalFotosTableCreateCompanionBuilder,
    $$LocalFotosTableUpdateCompanionBuilder,
    (FotoLocal, BaseReferences<_$AppDatabase, $LocalFotosTable, FotoLocal>),
    FotoLocal,
    PrefetchHooks Function()> {
  $$LocalFotosTableTableManager(_$AppDatabase db, $LocalFotosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> uuid = const Value.absent(),
            Value<String> consejoUuid = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String> descripcion = const Value.absent(),
            Value<bool> uploaded = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalFotosCompanion(
            uuid: uuid,
            consejoUuid: consejoUuid,
            path: path,
            descripcion: descripcion,
            uploaded: uploaded,
            error: error,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String uuid,
            required String consejoUuid,
            required String path,
            Value<String> descripcion = const Value.absent(),
            Value<bool> uploaded = const Value.absent(),
            Value<String?> error = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalFotosCompanion.insert(
            uuid: uuid,
            consejoUuid: consejoUuid,
            path: path,
            descripcion: descripcion,
            uploaded: uploaded,
            error: error,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalFotosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalFotosTable,
    FotoLocal,
    $$LocalFotosTableFilterComposer,
    $$LocalFotosTableOrderingComposer,
    $$LocalFotosTableAnnotationComposer,
    $$LocalFotosTableCreateCompanionBuilder,
    $$LocalFotosTableUpdateCompanionBuilder,
    (FotoLocal, BaseReferences<_$AppDatabase, $LocalFotosTable, FotoLocal>),
    FotoLocal,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedCatalogsTableTableManager get cachedCatalogs =>
      $$CachedCatalogsTableTableManager(_db, _db.cachedCatalogs);
  $$LocalConsejosTableTableManager get localConsejos =>
      $$LocalConsejosTableTableManager(_db, _db.localConsejos);
  $$LocalFotosTableTableManager get localFotos =>
      $$LocalFotosTableTableManager(_db, _db.localFotos);
}
