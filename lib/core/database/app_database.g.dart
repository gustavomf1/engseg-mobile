// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RascunhosTable extends Rascunhos
    with TableInfo<$RascunhosTable, Rascunho> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RascunhosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
      'tipo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
      'titulo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descricaoMeta =
      const VerificationMeta('descricao');
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
      'descricao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _severidadeMeta =
      const VerificationMeta('severidade');
  @override
  late final GeneratedColumn<int> severidade = GeneratedColumn<int>(
      'severidade', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _fotoPathMeta =
      const VerificationMeta('fotoPath');
  @override
  late final GeneratedColumn<String> fotoPath = GeneratedColumn<String>(
      'foto_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _capturedAtMeta =
      const VerificationMeta('capturedAt');
  @override
  late final GeneratedColumn<int> capturedAt = GeneratedColumn<int>(
      'captured_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dadosJsonMeta =
      const VerificationMeta('dadosJson');
  @override
  late final GeneratedColumn<String> dadosJson = GeneratedColumn<String>(
      'dados_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _criadoEmMeta =
      const VerificationMeta('criadoEm');
  @override
  late final GeneratedColumn<int> criadoEm = GeneratedColumn<int>(
      'criado_em', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sincronizadoMeta =
      const VerificationMeta('sincronizado');
  @override
  late final GeneratedColumn<int> sincronizado = GeneratedColumn<int>(
      'sincronizado', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tipo,
        titulo,
        descricao,
        severidade,
        fotoPath,
        latitude,
        longitude,
        capturedAt,
        dadosJson,
        criadoEm,
        sincronizado,
        serverId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rascunhos';
  @override
  VerificationContext validateIntegrity(Insertable<Rascunho> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
          _tipoMeta, tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta));
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('titulo')) {
      context.handle(_tituloMeta,
          titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta));
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(_descricaoMeta,
          descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta));
    }
    if (data.containsKey('severidade')) {
      context.handle(
          _severidadeMeta,
          severidade.isAcceptableOrUnknown(
              data['severidade']!, _severidadeMeta));
    }
    if (data.containsKey('foto_path')) {
      context.handle(_fotoPathMeta,
          fotoPath.isAcceptableOrUnknown(data['foto_path']!, _fotoPathMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('captured_at')) {
      context.handle(
          _capturedAtMeta,
          capturedAt.isAcceptableOrUnknown(
              data['captured_at']!, _capturedAtMeta));
    }
    if (data.containsKey('dados_json')) {
      context.handle(_dadosJsonMeta,
          dadosJson.isAcceptableOrUnknown(data['dados_json']!, _dadosJsonMeta));
    }
    if (data.containsKey('criado_em')) {
      context.handle(_criadoEmMeta,
          criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta));
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
          _sincronizadoMeta,
          sincronizado.isAcceptableOrUnknown(
              data['sincronizado']!, _sincronizadoMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Rascunho map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Rascunho(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo'])!,
      titulo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}titulo'])!,
      descricao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}descricao']),
      severidade: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}severidade']),
      fotoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}foto_path']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      capturedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}captured_at']),
      dadosJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dados_json']),
      criadoEm: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}criado_em'])!,
      sincronizado: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sincronizado'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
    );
  }

  @override
  $RascunhosTable createAlias(String alias) {
    return $RascunhosTable(attachedDatabase, alias);
  }
}

class Rascunho extends DataClass implements Insertable<Rascunho> {
  final String id;
  final String tipo;
  final String titulo;
  final String? descricao;
  final int? severidade;
  final String? fotoPath;
  final double? latitude;
  final double? longitude;
  final int? capturedAt;
  final String? dadosJson;
  final int criadoEm;
  final int sincronizado;
  final String? serverId;
  const Rascunho(
      {required this.id,
      required this.tipo,
      required this.titulo,
      this.descricao,
      this.severidade,
      this.fotoPath,
      this.latitude,
      this.longitude,
      this.capturedAt,
      this.dadosJson,
      required this.criadoEm,
      required this.sincronizado,
      this.serverId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tipo'] = Variable<String>(tipo);
    map['titulo'] = Variable<String>(titulo);
    if (!nullToAbsent || descricao != null) {
      map['descricao'] = Variable<String>(descricao);
    }
    if (!nullToAbsent || severidade != null) {
      map['severidade'] = Variable<int>(severidade);
    }
    if (!nullToAbsent || fotoPath != null) {
      map['foto_path'] = Variable<String>(fotoPath);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || capturedAt != null) {
      map['captured_at'] = Variable<int>(capturedAt);
    }
    if (!nullToAbsent || dadosJson != null) {
      map['dados_json'] = Variable<String>(dadosJson);
    }
    map['criado_em'] = Variable<int>(criadoEm);
    map['sincronizado'] = Variable<int>(sincronizado);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    return map;
  }

  RascunhosCompanion toCompanion(bool nullToAbsent) {
    return RascunhosCompanion(
      id: Value(id),
      tipo: Value(tipo),
      titulo: Value(titulo),
      descricao: descricao == null && nullToAbsent
          ? const Value.absent()
          : Value(descricao),
      severidade: severidade == null && nullToAbsent
          ? const Value.absent()
          : Value(severidade),
      fotoPath: fotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoPath),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      capturedAt: capturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(capturedAt),
      dadosJson: dadosJson == null && nullToAbsent
          ? const Value.absent()
          : Value(dadosJson),
      criadoEm: Value(criadoEm),
      sincronizado: Value(sincronizado),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
    );
  }

  factory Rascunho.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Rascunho(
      id: serializer.fromJson<String>(json['id']),
      tipo: serializer.fromJson<String>(json['tipo']),
      titulo: serializer.fromJson<String>(json['titulo']),
      descricao: serializer.fromJson<String?>(json['descricao']),
      severidade: serializer.fromJson<int?>(json['severidade']),
      fotoPath: serializer.fromJson<String?>(json['fotoPath']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      capturedAt: serializer.fromJson<int?>(json['capturedAt']),
      dadosJson: serializer.fromJson<String?>(json['dadosJson']),
      criadoEm: serializer.fromJson<int>(json['criadoEm']),
      sincronizado: serializer.fromJson<int>(json['sincronizado']),
      serverId: serializer.fromJson<String?>(json['serverId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tipo': serializer.toJson<String>(tipo),
      'titulo': serializer.toJson<String>(titulo),
      'descricao': serializer.toJson<String?>(descricao),
      'severidade': serializer.toJson<int?>(severidade),
      'fotoPath': serializer.toJson<String?>(fotoPath),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'capturedAt': serializer.toJson<int?>(capturedAt),
      'dadosJson': serializer.toJson<String?>(dadosJson),
      'criadoEm': serializer.toJson<int>(criadoEm),
      'sincronizado': serializer.toJson<int>(sincronizado),
      'serverId': serializer.toJson<String?>(serverId),
    };
  }

  Rascunho copyWith(
          {String? id,
          String? tipo,
          String? titulo,
          Value<String?> descricao = const Value.absent(),
          Value<int?> severidade = const Value.absent(),
          Value<String?> fotoPath = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<int?> capturedAt = const Value.absent(),
          Value<String?> dadosJson = const Value.absent(),
          int? criadoEm,
          int? sincronizado,
          Value<String?> serverId = const Value.absent()}) =>
      Rascunho(
        id: id ?? this.id,
        tipo: tipo ?? this.tipo,
        titulo: titulo ?? this.titulo,
        descricao: descricao.present ? descricao.value : this.descricao,
        severidade: severidade.present ? severidade.value : this.severidade,
        fotoPath: fotoPath.present ? fotoPath.value : this.fotoPath,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        capturedAt: capturedAt.present ? capturedAt.value : this.capturedAt,
        dadosJson: dadosJson.present ? dadosJson.value : this.dadosJson,
        criadoEm: criadoEm ?? this.criadoEm,
        sincronizado: sincronizado ?? this.sincronizado,
        serverId: serverId.present ? serverId.value : this.serverId,
      );
  Rascunho copyWithCompanion(RascunhosCompanion data) {
    return Rascunho(
      id: data.id.present ? data.id.value : this.id,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      severidade:
          data.severidade.present ? data.severidade.value : this.severidade,
      fotoPath: data.fotoPath.present ? data.fotoPath.value : this.fotoPath,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      capturedAt:
          data.capturedAt.present ? data.capturedAt.value : this.capturedAt,
      dadosJson: data.dadosJson.present ? data.dadosJson.value : this.dadosJson,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Rascunho(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('titulo: $titulo, ')
          ..write('descricao: $descricao, ')
          ..write('severidade: $severidade, ')
          ..write('fotoPath: $fotoPath, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('dadosJson: $dadosJson, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('serverId: $serverId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tipo,
      titulo,
      descricao,
      severidade,
      fotoPath,
      latitude,
      longitude,
      capturedAt,
      dadosJson,
      criadoEm,
      sincronizado,
      serverId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Rascunho &&
          other.id == this.id &&
          other.tipo == this.tipo &&
          other.titulo == this.titulo &&
          other.descricao == this.descricao &&
          other.severidade == this.severidade &&
          other.fotoPath == this.fotoPath &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.capturedAt == this.capturedAt &&
          other.dadosJson == this.dadosJson &&
          other.criadoEm == this.criadoEm &&
          other.sincronizado == this.sincronizado &&
          other.serverId == this.serverId);
}

class RascunhosCompanion extends UpdateCompanion<Rascunho> {
  final Value<String> id;
  final Value<String> tipo;
  final Value<String> titulo;
  final Value<String?> descricao;
  final Value<int?> severidade;
  final Value<String?> fotoPath;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<int?> capturedAt;
  final Value<String?> dadosJson;
  final Value<int> criadoEm;
  final Value<int> sincronizado;
  final Value<String?> serverId;
  final Value<int> rowid;
  const RascunhosCompanion({
    this.id = const Value.absent(),
    this.tipo = const Value.absent(),
    this.titulo = const Value.absent(),
    this.descricao = const Value.absent(),
    this.severidade = const Value.absent(),
    this.fotoPath = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.dadosJson = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.serverId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RascunhosCompanion.insert({
    required String id,
    required String tipo,
    required String titulo,
    this.descricao = const Value.absent(),
    this.severidade = const Value.absent(),
    this.fotoPath = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.dadosJson = const Value.absent(),
    required int criadoEm,
    this.sincronizado = const Value.absent(),
    this.serverId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tipo = Value(tipo),
        titulo = Value(titulo),
        criadoEm = Value(criadoEm);
  static Insertable<Rascunho> custom({
    Expression<String>? id,
    Expression<String>? tipo,
    Expression<String>? titulo,
    Expression<String>? descricao,
    Expression<int>? severidade,
    Expression<String>? fotoPath,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? capturedAt,
    Expression<String>? dadosJson,
    Expression<int>? criadoEm,
    Expression<int>? sincronizado,
    Expression<String>? serverId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tipo != null) 'tipo': tipo,
      if (titulo != null) 'titulo': titulo,
      if (descricao != null) 'descricao': descricao,
      if (severidade != null) 'severidade': severidade,
      if (fotoPath != null) 'foto_path': fotoPath,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (dadosJson != null) 'dados_json': dadosJson,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (serverId != null) 'server_id': serverId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RascunhosCompanion copyWith(
      {Value<String>? id,
      Value<String>? tipo,
      Value<String>? titulo,
      Value<String?>? descricao,
      Value<int?>? severidade,
      Value<String?>? fotoPath,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<int?>? capturedAt,
      Value<String?>? dadosJson,
      Value<int>? criadoEm,
      Value<int>? sincronizado,
      Value<String?>? serverId,
      Value<int>? rowid}) {
    return RascunhosCompanion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      severidade: severidade ?? this.severidade,
      fotoPath: fotoPath ?? this.fotoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      capturedAt: capturedAt ?? this.capturedAt,
      dadosJson: dadosJson ?? this.dadosJson,
      criadoEm: criadoEm ?? this.criadoEm,
      sincronizado: sincronizado ?? this.sincronizado,
      serverId: serverId ?? this.serverId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (severidade.present) {
      map['severidade'] = Variable<int>(severidade.value);
    }
    if (fotoPath.present) {
      map['foto_path'] = Variable<String>(fotoPath.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<int>(capturedAt.value);
    }
    if (dadosJson.present) {
      map['dados_json'] = Variable<String>(dadosJson.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<int>(criadoEm.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<int>(sincronizado.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RascunhosCompanion(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('titulo: $titulo, ')
          ..write('descricao: $descricao, ')
          ..write('severidade: $severidade, ')
          ..write('fotoPath: $fotoPath, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('dadosJson: $dadosJson, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('serverId: $serverId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OcorrenciasCacheTable extends OcorrenciasCache
    with TableInfo<$OcorrenciasCacheTable, OcorrenciasCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OcorrenciasCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
      'tipo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dadosJsonMeta =
      const VerificationMeta('dadosJson');
  @override
  late final GeneratedColumn<String> dadosJson = GeneratedColumn<String>(
      'dados_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usuarioIdMeta =
      const VerificationMeta('usuarioId');
  @override
  late final GeneratedColumn<String> usuarioId = GeneratedColumn<String>(
      'usuario_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedEmMeta =
      const VerificationMeta('cachedEm');
  @override
  late final GeneratedColumn<int> cachedEm = GeneratedColumn<int>(
      'cached_em', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, tipo, dadosJson, usuarioId, cachedEm];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ocorrencias_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<OcorrenciasCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
          _tipoMeta, tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta));
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('dados_json')) {
      context.handle(_dadosJsonMeta,
          dadosJson.isAcceptableOrUnknown(data['dados_json']!, _dadosJsonMeta));
    } else if (isInserting) {
      context.missing(_dadosJsonMeta);
    }
    if (data.containsKey('usuario_id')) {
      context.handle(_usuarioIdMeta,
          usuarioId.isAcceptableOrUnknown(data['usuario_id']!, _usuarioIdMeta));
    } else if (isInserting) {
      context.missing(_usuarioIdMeta);
    }
    if (data.containsKey('cached_em')) {
      context.handle(_cachedEmMeta,
          cachedEm.isAcceptableOrUnknown(data['cached_em']!, _cachedEmMeta));
    } else if (isInserting) {
      context.missing(_cachedEmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OcorrenciasCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OcorrenciasCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      tipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo'])!,
      dadosJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dados_json'])!,
      usuarioId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}usuario_id'])!,
      cachedEm: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_em'])!,
    );
  }

  @override
  $OcorrenciasCacheTable createAlias(String alias) {
    return $OcorrenciasCacheTable(attachedDatabase, alias);
  }
}

class OcorrenciasCacheData extends DataClass
    implements Insertable<OcorrenciasCacheData> {
  final String id;
  final String tipo;
  final String dadosJson;
  final String usuarioId;
  final int cachedEm;
  const OcorrenciasCacheData(
      {required this.id,
      required this.tipo,
      required this.dadosJson,
      required this.usuarioId,
      required this.cachedEm});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tipo'] = Variable<String>(tipo);
    map['dados_json'] = Variable<String>(dadosJson);
    map['usuario_id'] = Variable<String>(usuarioId);
    map['cached_em'] = Variable<int>(cachedEm);
    return map;
  }

  OcorrenciasCacheCompanion toCompanion(bool nullToAbsent) {
    return OcorrenciasCacheCompanion(
      id: Value(id),
      tipo: Value(tipo),
      dadosJson: Value(dadosJson),
      usuarioId: Value(usuarioId),
      cachedEm: Value(cachedEm),
    );
  }

  factory OcorrenciasCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OcorrenciasCacheData(
      id: serializer.fromJson<String>(json['id']),
      tipo: serializer.fromJson<String>(json['tipo']),
      dadosJson: serializer.fromJson<String>(json['dadosJson']),
      usuarioId: serializer.fromJson<String>(json['usuarioId']),
      cachedEm: serializer.fromJson<int>(json['cachedEm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tipo': serializer.toJson<String>(tipo),
      'dadosJson': serializer.toJson<String>(dadosJson),
      'usuarioId': serializer.toJson<String>(usuarioId),
      'cachedEm': serializer.toJson<int>(cachedEm),
    };
  }

  OcorrenciasCacheData copyWith(
          {String? id,
          String? tipo,
          String? dadosJson,
          String? usuarioId,
          int? cachedEm}) =>
      OcorrenciasCacheData(
        id: id ?? this.id,
        tipo: tipo ?? this.tipo,
        dadosJson: dadosJson ?? this.dadosJson,
        usuarioId: usuarioId ?? this.usuarioId,
        cachedEm: cachedEm ?? this.cachedEm,
      );
  OcorrenciasCacheData copyWithCompanion(OcorrenciasCacheCompanion data) {
    return OcorrenciasCacheData(
      id: data.id.present ? data.id.value : this.id,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      dadosJson: data.dadosJson.present ? data.dadosJson.value : this.dadosJson,
      usuarioId: data.usuarioId.present ? data.usuarioId.value : this.usuarioId,
      cachedEm: data.cachedEm.present ? data.cachedEm.value : this.cachedEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OcorrenciasCacheData(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('dadosJson: $dadosJson, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('cachedEm: $cachedEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tipo, dadosJson, usuarioId, cachedEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OcorrenciasCacheData &&
          other.id == this.id &&
          other.tipo == this.tipo &&
          other.dadosJson == this.dadosJson &&
          other.usuarioId == this.usuarioId &&
          other.cachedEm == this.cachedEm);
}

class OcorrenciasCacheCompanion extends UpdateCompanion<OcorrenciasCacheData> {
  final Value<String> id;
  final Value<String> tipo;
  final Value<String> dadosJson;
  final Value<String> usuarioId;
  final Value<int> cachedEm;
  final Value<int> rowid;
  const OcorrenciasCacheCompanion({
    this.id = const Value.absent(),
    this.tipo = const Value.absent(),
    this.dadosJson = const Value.absent(),
    this.usuarioId = const Value.absent(),
    this.cachedEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OcorrenciasCacheCompanion.insert({
    required String id,
    required String tipo,
    required String dadosJson,
    required String usuarioId,
    required int cachedEm,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        tipo = Value(tipo),
        dadosJson = Value(dadosJson),
        usuarioId = Value(usuarioId),
        cachedEm = Value(cachedEm);
  static Insertable<OcorrenciasCacheData> custom({
    Expression<String>? id,
    Expression<String>? tipo,
    Expression<String>? dadosJson,
    Expression<String>? usuarioId,
    Expression<int>? cachedEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tipo != null) 'tipo': tipo,
      if (dadosJson != null) 'dados_json': dadosJson,
      if (usuarioId != null) 'usuario_id': usuarioId,
      if (cachedEm != null) 'cached_em': cachedEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OcorrenciasCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? tipo,
      Value<String>? dadosJson,
      Value<String>? usuarioId,
      Value<int>? cachedEm,
      Value<int>? rowid}) {
    return OcorrenciasCacheCompanion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      dadosJson: dadosJson ?? this.dadosJson,
      usuarioId: usuarioId ?? this.usuarioId,
      cachedEm: cachedEm ?? this.cachedEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (dadosJson.present) {
      map['dados_json'] = Variable<String>(dadosJson.value);
    }
    if (usuarioId.present) {
      map['usuario_id'] = Variable<String>(usuarioId.value);
    }
    if (cachedEm.present) {
      map['cached_em'] = Variable<int>(cachedEm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OcorrenciasCacheCompanion(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('dadosJson: $dadosJson, ')
          ..write('usuarioId: $usuarioId, ')
          ..write('cachedEm: $cachedEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RascunhosTable rascunhos = $RascunhosTable(this);
  late final $OcorrenciasCacheTable ocorrenciasCache =
      $OcorrenciasCacheTable(this);
  late final RascunhosDao rascunhosDao = RascunhosDao(this as AppDatabase);
  late final OcorrenciasCacheDao ocorrenciasCacheDao =
      OcorrenciasCacheDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [rascunhos, ocorrenciasCache];
}

typedef $$RascunhosTableCreateCompanionBuilder = RascunhosCompanion Function({
  required String id,
  required String tipo,
  required String titulo,
  Value<String?> descricao,
  Value<int?> severidade,
  Value<String?> fotoPath,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<int?> capturedAt,
  Value<String?> dadosJson,
  required int criadoEm,
  Value<int> sincronizado,
  Value<String?> serverId,
  Value<int> rowid,
});
typedef $$RascunhosTableUpdateCompanionBuilder = RascunhosCompanion Function({
  Value<String> id,
  Value<String> tipo,
  Value<String> titulo,
  Value<String?> descricao,
  Value<int?> severidade,
  Value<String?> fotoPath,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<int?> capturedAt,
  Value<String?> dadosJson,
  Value<int> criadoEm,
  Value<int> sincronizado,
  Value<String?> serverId,
  Value<int> rowid,
});

class $$RascunhosTableFilterComposer
    extends Composer<_$AppDatabase, $RascunhosTable> {
  $$RascunhosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get titulo => $composableBuilder(
      column: $table.titulo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get severidade => $composableBuilder(
      column: $table.severidade, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fotoPath => $composableBuilder(
      column: $table.fotoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dadosJson => $composableBuilder(
      column: $table.dadosJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get criadoEm => $composableBuilder(
      column: $table.criadoEm, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));
}

class $$RascunhosTableOrderingComposer
    extends Composer<_$AppDatabase, $RascunhosTable> {
  $$RascunhosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get titulo => $composableBuilder(
      column: $table.titulo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descricao => $composableBuilder(
      column: $table.descricao, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get severidade => $composableBuilder(
      column: $table.severidade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fotoPath => $composableBuilder(
      column: $table.fotoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dadosJson => $composableBuilder(
      column: $table.dadosJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get criadoEm => $composableBuilder(
      column: $table.criadoEm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sincronizado => $composableBuilder(
      column: $table.sincronizado,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));
}

class $$RascunhosTableAnnotationComposer
    extends Composer<_$AppDatabase, $RascunhosTable> {
  $$RascunhosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<int> get severidade => $composableBuilder(
      column: $table.severidade, builder: (column) => column);

  GeneratedColumn<String> get fotoPath =>
      $composableBuilder(column: $table.fotoPath, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get capturedAt => $composableBuilder(
      column: $table.capturedAt, builder: (column) => column);

  GeneratedColumn<String> get dadosJson =>
      $composableBuilder(column: $table.dadosJson, builder: (column) => column);

  GeneratedColumn<int> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  GeneratedColumn<int> get sincronizado => $composableBuilder(
      column: $table.sincronizado, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);
}

class $$RascunhosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RascunhosTable,
    Rascunho,
    $$RascunhosTableFilterComposer,
    $$RascunhosTableOrderingComposer,
    $$RascunhosTableAnnotationComposer,
    $$RascunhosTableCreateCompanionBuilder,
    $$RascunhosTableUpdateCompanionBuilder,
    (Rascunho, BaseReferences<_$AppDatabase, $RascunhosTable, Rascunho>),
    Rascunho,
    PrefetchHooks Function()> {
  $$RascunhosTableTableManager(_$AppDatabase db, $RascunhosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RascunhosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RascunhosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RascunhosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<String> titulo = const Value.absent(),
            Value<String?> descricao = const Value.absent(),
            Value<int?> severidade = const Value.absent(),
            Value<String?> fotoPath = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<int?> capturedAt = const Value.absent(),
            Value<String?> dadosJson = const Value.absent(),
            Value<int> criadoEm = const Value.absent(),
            Value<int> sincronizado = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RascunhosCompanion(
            id: id,
            tipo: tipo,
            titulo: titulo,
            descricao: descricao,
            severidade: severidade,
            fotoPath: fotoPath,
            latitude: latitude,
            longitude: longitude,
            capturedAt: capturedAt,
            dadosJson: dadosJson,
            criadoEm: criadoEm,
            sincronizado: sincronizado,
            serverId: serverId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tipo,
            required String titulo,
            Value<String?> descricao = const Value.absent(),
            Value<int?> severidade = const Value.absent(),
            Value<String?> fotoPath = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<int?> capturedAt = const Value.absent(),
            Value<String?> dadosJson = const Value.absent(),
            required int criadoEm,
            Value<int> sincronizado = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RascunhosCompanion.insert(
            id: id,
            tipo: tipo,
            titulo: titulo,
            descricao: descricao,
            severidade: severidade,
            fotoPath: fotoPath,
            latitude: latitude,
            longitude: longitude,
            capturedAt: capturedAt,
            dadosJson: dadosJson,
            criadoEm: criadoEm,
            sincronizado: sincronizado,
            serverId: serverId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RascunhosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RascunhosTable,
    Rascunho,
    $$RascunhosTableFilterComposer,
    $$RascunhosTableOrderingComposer,
    $$RascunhosTableAnnotationComposer,
    $$RascunhosTableCreateCompanionBuilder,
    $$RascunhosTableUpdateCompanionBuilder,
    (Rascunho, BaseReferences<_$AppDatabase, $RascunhosTable, Rascunho>),
    Rascunho,
    PrefetchHooks Function()>;
typedef $$OcorrenciasCacheTableCreateCompanionBuilder
    = OcorrenciasCacheCompanion Function({
  required String id,
  required String tipo,
  required String dadosJson,
  required String usuarioId,
  required int cachedEm,
  Value<int> rowid,
});
typedef $$OcorrenciasCacheTableUpdateCompanionBuilder
    = OcorrenciasCacheCompanion Function({
  Value<String> id,
  Value<String> tipo,
  Value<String> dadosJson,
  Value<String> usuarioId,
  Value<int> cachedEm,
  Value<int> rowid,
});

class $$OcorrenciasCacheTableFilterComposer
    extends Composer<_$AppDatabase, $OcorrenciasCacheTable> {
  $$OcorrenciasCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dadosJson => $composableBuilder(
      column: $table.dadosJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get usuarioId => $composableBuilder(
      column: $table.usuarioId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedEm => $composableBuilder(
      column: $table.cachedEm, builder: (column) => ColumnFilters(column));
}

class $$OcorrenciasCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $OcorrenciasCacheTable> {
  $$OcorrenciasCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tipo => $composableBuilder(
      column: $table.tipo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dadosJson => $composableBuilder(
      column: $table.dadosJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get usuarioId => $composableBuilder(
      column: $table.usuarioId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedEm => $composableBuilder(
      column: $table.cachedEm, builder: (column) => ColumnOrderings(column));
}

class $$OcorrenciasCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $OcorrenciasCacheTable> {
  $$OcorrenciasCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get dadosJson =>
      $composableBuilder(column: $table.dadosJson, builder: (column) => column);

  GeneratedColumn<String> get usuarioId =>
      $composableBuilder(column: $table.usuarioId, builder: (column) => column);

  GeneratedColumn<int> get cachedEm =>
      $composableBuilder(column: $table.cachedEm, builder: (column) => column);
}

class $$OcorrenciasCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OcorrenciasCacheTable,
    OcorrenciasCacheData,
    $$OcorrenciasCacheTableFilterComposer,
    $$OcorrenciasCacheTableOrderingComposer,
    $$OcorrenciasCacheTableAnnotationComposer,
    $$OcorrenciasCacheTableCreateCompanionBuilder,
    $$OcorrenciasCacheTableUpdateCompanionBuilder,
    (
      OcorrenciasCacheData,
      BaseReferences<_$AppDatabase, $OcorrenciasCacheTable,
          OcorrenciasCacheData>
    ),
    OcorrenciasCacheData,
    PrefetchHooks Function()> {
  $$OcorrenciasCacheTableTableManager(
      _$AppDatabase db, $OcorrenciasCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OcorrenciasCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OcorrenciasCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OcorrenciasCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<String> dadosJson = const Value.absent(),
            Value<String> usuarioId = const Value.absent(),
            Value<int> cachedEm = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OcorrenciasCacheCompanion(
            id: id,
            tipo: tipo,
            dadosJson: dadosJson,
            usuarioId: usuarioId,
            cachedEm: cachedEm,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String tipo,
            required String dadosJson,
            required String usuarioId,
            required int cachedEm,
            Value<int> rowid = const Value.absent(),
          }) =>
              OcorrenciasCacheCompanion.insert(
            id: id,
            tipo: tipo,
            dadosJson: dadosJson,
            usuarioId: usuarioId,
            cachedEm: cachedEm,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OcorrenciasCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OcorrenciasCacheTable,
    OcorrenciasCacheData,
    $$OcorrenciasCacheTableFilterComposer,
    $$OcorrenciasCacheTableOrderingComposer,
    $$OcorrenciasCacheTableAnnotationComposer,
    $$OcorrenciasCacheTableCreateCompanionBuilder,
    $$OcorrenciasCacheTableUpdateCompanionBuilder,
    (
      OcorrenciasCacheData,
      BaseReferences<_$AppDatabase, $OcorrenciasCacheTable,
          OcorrenciasCacheData>
    ),
    OcorrenciasCacheData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RascunhosTableTableManager get rascunhos =>
      $$RascunhosTableTableManager(_db, _db.rascunhos);
  $$OcorrenciasCacheTableTableManager get ocorrenciasCache =>
      $$OcorrenciasCacheTableTableManager(_db, _db.ocorrenciasCache);
}
