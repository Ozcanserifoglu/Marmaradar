// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedCamerasTable extends CachedCameras
    with TableInfo<$CachedCamerasTable, CachedCamera> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCamerasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _maxspeedKmhMeta = const VerificationMeta(
    'maxspeedKmh',
  );
  @override
  late final GeneratedColumn<int> maxspeedKmh = GeneratedColumn<int>(
    'maxspeed_kmh',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directionDegMeta = const VerificationMeta(
    'directionDeg',
  );
  @override
  late final GeneratedColumn<int> directionDeg = GeneratedColumn<int>(
    'direction_deg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directionToleranceDegMeta =
      const VerificationMeta('directionToleranceDeg');
  @override
  late final GeneratedColumn<int> directionToleranceDeg = GeneratedColumn<int>(
    'direction_tolerance_deg',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(35),
  );
  static const VerificationMeta _roadNameMeta = const VerificationMeta(
    'roadName',
  );
  @override
  late final GeneratedColumn<String> roadName = GeneratedColumn<String>(
    'road_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cameraTypeMeta = const VerificationMeta(
    'cameraType',
  );
  @override
  late final GeneratedColumn<String> cameraType = GeneratedColumn<String>(
    'camera_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fixed'),
  );
  static const VerificationMeta _regionCodeMeta = const VerificationMeta(
    'regionCode',
  );
  @override
  late final GeneratedColumn<String> regionCode = GeneratedColumn<String>(
    'region_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('bursa'),
  );
  static const VerificationMeta _alertRadiusMMeta = const VerificationMeta(
    'alertRadiusM',
  );
  @override
  late final GeneratedColumn<double> alertRadiusM = GeneratedColumn<double>(
    'alert_radius_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lat,
    lon,
    maxspeedKmh,
    directionDeg,
    directionToleranceDeg,
    roadName,
    cameraType,
    regionCode,
    alertRadiusM,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_cameras';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCamera> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('maxspeed_kmh')) {
      context.handle(
        _maxspeedKmhMeta,
        maxspeedKmh.isAcceptableOrUnknown(
          data['maxspeed_kmh']!,
          _maxspeedKmhMeta,
        ),
      );
    }
    if (data.containsKey('direction_deg')) {
      context.handle(
        _directionDegMeta,
        directionDeg.isAcceptableOrUnknown(
          data['direction_deg']!,
          _directionDegMeta,
        ),
      );
    }
    if (data.containsKey('direction_tolerance_deg')) {
      context.handle(
        _directionToleranceDegMeta,
        directionToleranceDeg.isAcceptableOrUnknown(
          data['direction_tolerance_deg']!,
          _directionToleranceDegMeta,
        ),
      );
    }
    if (data.containsKey('road_name')) {
      context.handle(
        _roadNameMeta,
        roadName.isAcceptableOrUnknown(data['road_name']!, _roadNameMeta),
      );
    }
    if (data.containsKey('camera_type')) {
      context.handle(
        _cameraTypeMeta,
        cameraType.isAcceptableOrUnknown(data['camera_type']!, _cameraTypeMeta),
      );
    }
    if (data.containsKey('region_code')) {
      context.handle(
        _regionCodeMeta,
        regionCode.isAcceptableOrUnknown(data['region_code']!, _regionCodeMeta),
      );
    }
    if (data.containsKey('alert_radius_m')) {
      context.handle(
        _alertRadiusMMeta,
        alertRadiusM.isAcceptableOrUnknown(
          data['alert_radius_m']!,
          _alertRadiusMMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCamera map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCamera(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      maxspeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maxspeed_kmh'],
      ),
      directionDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction_deg'],
      ),
      directionToleranceDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction_tolerance_deg'],
      )!,
      roadName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}road_name'],
      ),
      cameraType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}camera_type'],
      )!,
      regionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_code'],
      )!,
      alertRadiusM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alert_radius_m'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedCamerasTable createAlias(String alias) {
    return $CachedCamerasTable(attachedDatabase, alias);
  }
}

class CachedCamera extends DataClass implements Insertable<CachedCamera> {
  final int id;
  final double lat;
  final double lon;
  final int? maxspeedKmh;
  final int? directionDeg;
  final int directionToleranceDeg;
  final String? roadName;
  final String cameraType;
  final String regionCode;
  final double alertRadiusM;
  final DateTime updatedAt;
  const CachedCamera({
    required this.id,
    required this.lat,
    required this.lon,
    this.maxspeedKmh,
    this.directionDeg,
    required this.directionToleranceDeg,
    this.roadName,
    required this.cameraType,
    required this.regionCode,
    required this.alertRadiusM,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || maxspeedKmh != null) {
      map['maxspeed_kmh'] = Variable<int>(maxspeedKmh);
    }
    if (!nullToAbsent || directionDeg != null) {
      map['direction_deg'] = Variable<int>(directionDeg);
    }
    map['direction_tolerance_deg'] = Variable<int>(directionToleranceDeg);
    if (!nullToAbsent || roadName != null) {
      map['road_name'] = Variable<String>(roadName);
    }
    map['camera_type'] = Variable<String>(cameraType);
    map['region_code'] = Variable<String>(regionCode);
    map['alert_radius_m'] = Variable<double>(alertRadiusM);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedCamerasCompanion toCompanion(bool nullToAbsent) {
    return CachedCamerasCompanion(
      id: Value(id),
      lat: Value(lat),
      lon: Value(lon),
      maxspeedKmh: maxspeedKmh == null && nullToAbsent
          ? const Value.absent()
          : Value(maxspeedKmh),
      directionDeg: directionDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(directionDeg),
      directionToleranceDeg: Value(directionToleranceDeg),
      roadName: roadName == null && nullToAbsent
          ? const Value.absent()
          : Value(roadName),
      cameraType: Value(cameraType),
      regionCode: Value(regionCode),
      alertRadiusM: Value(alertRadiusM),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedCamera.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCamera(
      id: serializer.fromJson<int>(json['id']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      maxspeedKmh: serializer.fromJson<int?>(json['maxspeedKmh']),
      directionDeg: serializer.fromJson<int?>(json['directionDeg']),
      directionToleranceDeg: serializer.fromJson<int>(
        json['directionToleranceDeg'],
      ),
      roadName: serializer.fromJson<String?>(json['roadName']),
      cameraType: serializer.fromJson<String>(json['cameraType']),
      regionCode: serializer.fromJson<String>(json['regionCode']),
      alertRadiusM: serializer.fromJson<double>(json['alertRadiusM']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'maxspeedKmh': serializer.toJson<int?>(maxspeedKmh),
      'directionDeg': serializer.toJson<int?>(directionDeg),
      'directionToleranceDeg': serializer.toJson<int>(directionToleranceDeg),
      'roadName': serializer.toJson<String?>(roadName),
      'cameraType': serializer.toJson<String>(cameraType),
      'regionCode': serializer.toJson<String>(regionCode),
      'alertRadiusM': serializer.toJson<double>(alertRadiusM),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedCamera copyWith({
    int? id,
    double? lat,
    double? lon,
    Value<int?> maxspeedKmh = const Value.absent(),
    Value<int?> directionDeg = const Value.absent(),
    int? directionToleranceDeg,
    Value<String?> roadName = const Value.absent(),
    String? cameraType,
    String? regionCode,
    double? alertRadiusM,
    DateTime? updatedAt,
  }) => CachedCamera(
    id: id ?? this.id,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    maxspeedKmh: maxspeedKmh.present ? maxspeedKmh.value : this.maxspeedKmh,
    directionDeg: directionDeg.present ? directionDeg.value : this.directionDeg,
    directionToleranceDeg: directionToleranceDeg ?? this.directionToleranceDeg,
    roadName: roadName.present ? roadName.value : this.roadName,
    cameraType: cameraType ?? this.cameraType,
    regionCode: regionCode ?? this.regionCode,
    alertRadiusM: alertRadiusM ?? this.alertRadiusM,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedCamera copyWithCompanion(CachedCamerasCompanion data) {
    return CachedCamera(
      id: data.id.present ? data.id.value : this.id,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      maxspeedKmh: data.maxspeedKmh.present
          ? data.maxspeedKmh.value
          : this.maxspeedKmh,
      directionDeg: data.directionDeg.present
          ? data.directionDeg.value
          : this.directionDeg,
      directionToleranceDeg: data.directionToleranceDeg.present
          ? data.directionToleranceDeg.value
          : this.directionToleranceDeg,
      roadName: data.roadName.present ? data.roadName.value : this.roadName,
      cameraType: data.cameraType.present
          ? data.cameraType.value
          : this.cameraType,
      regionCode: data.regionCode.present
          ? data.regionCode.value
          : this.regionCode,
      alertRadiusM: data.alertRadiusM.present
          ? data.alertRadiusM.value
          : this.alertRadiusM,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCamera(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('maxspeedKmh: $maxspeedKmh, ')
          ..write('directionDeg: $directionDeg, ')
          ..write('directionToleranceDeg: $directionToleranceDeg, ')
          ..write('roadName: $roadName, ')
          ..write('cameraType: $cameraType, ')
          ..write('regionCode: $regionCode, ')
          ..write('alertRadiusM: $alertRadiusM, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lat,
    lon,
    maxspeedKmh,
    directionDeg,
    directionToleranceDeg,
    roadName,
    cameraType,
    regionCode,
    alertRadiusM,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCamera &&
          other.id == this.id &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.maxspeedKmh == this.maxspeedKmh &&
          other.directionDeg == this.directionDeg &&
          other.directionToleranceDeg == this.directionToleranceDeg &&
          other.roadName == this.roadName &&
          other.cameraType == this.cameraType &&
          other.regionCode == this.regionCode &&
          other.alertRadiusM == this.alertRadiusM &&
          other.updatedAt == this.updatedAt);
}

class CachedCamerasCompanion extends UpdateCompanion<CachedCamera> {
  final Value<int> id;
  final Value<double> lat;
  final Value<double> lon;
  final Value<int?> maxspeedKmh;
  final Value<int?> directionDeg;
  final Value<int> directionToleranceDeg;
  final Value<String?> roadName;
  final Value<String> cameraType;
  final Value<String> regionCode;
  final Value<double> alertRadiusM;
  final Value<DateTime> updatedAt;
  const CachedCamerasCompanion({
    this.id = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.maxspeedKmh = const Value.absent(),
    this.directionDeg = const Value.absent(),
    this.directionToleranceDeg = const Value.absent(),
    this.roadName = const Value.absent(),
    this.cameraType = const Value.absent(),
    this.regionCode = const Value.absent(),
    this.alertRadiusM = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CachedCamerasCompanion.insert({
    this.id = const Value.absent(),
    required double lat,
    required double lon,
    this.maxspeedKmh = const Value.absent(),
    this.directionDeg = const Value.absent(),
    this.directionToleranceDeg = const Value.absent(),
    this.roadName = const Value.absent(),
    this.cameraType = const Value.absent(),
    this.regionCode = const Value.absent(),
    this.alertRadiusM = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : lat = Value(lat),
       lon = Value(lon);
  static Insertable<CachedCamera> custom({
    Expression<int>? id,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<int>? maxspeedKmh,
    Expression<int>? directionDeg,
    Expression<int>? directionToleranceDeg,
    Expression<String>? roadName,
    Expression<String>? cameraType,
    Expression<String>? regionCode,
    Expression<double>? alertRadiusM,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (maxspeedKmh != null) 'maxspeed_kmh': maxspeedKmh,
      if (directionDeg != null) 'direction_deg': directionDeg,
      if (directionToleranceDeg != null)
        'direction_tolerance_deg': directionToleranceDeg,
      if (roadName != null) 'road_name': roadName,
      if (cameraType != null) 'camera_type': cameraType,
      if (regionCode != null) 'region_code': regionCode,
      if (alertRadiusM != null) 'alert_radius_m': alertRadiusM,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CachedCamerasCompanion copyWith({
    Value<int>? id,
    Value<double>? lat,
    Value<double>? lon,
    Value<int?>? maxspeedKmh,
    Value<int?>? directionDeg,
    Value<int>? directionToleranceDeg,
    Value<String?>? roadName,
    Value<String>? cameraType,
    Value<String>? regionCode,
    Value<double>? alertRadiusM,
    Value<DateTime>? updatedAt,
  }) {
    return CachedCamerasCompanion(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      maxspeedKmh: maxspeedKmh ?? this.maxspeedKmh,
      directionDeg: directionDeg ?? this.directionDeg,
      directionToleranceDeg:
          directionToleranceDeg ?? this.directionToleranceDeg,
      roadName: roadName ?? this.roadName,
      cameraType: cameraType ?? this.cameraType,
      regionCode: regionCode ?? this.regionCode,
      alertRadiusM: alertRadiusM ?? this.alertRadiusM,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (maxspeedKmh.present) {
      map['maxspeed_kmh'] = Variable<int>(maxspeedKmh.value);
    }
    if (directionDeg.present) {
      map['direction_deg'] = Variable<int>(directionDeg.value);
    }
    if (directionToleranceDeg.present) {
      map['direction_tolerance_deg'] = Variable<int>(
        directionToleranceDeg.value,
      );
    }
    if (roadName.present) {
      map['road_name'] = Variable<String>(roadName.value);
    }
    if (cameraType.present) {
      map['camera_type'] = Variable<String>(cameraType.value);
    }
    if (regionCode.present) {
      map['region_code'] = Variable<String>(regionCode.value);
    }
    if (alertRadiusM.present) {
      map['alert_radius_m'] = Variable<double>(alertRadiusM.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCamerasCompanion(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('maxspeedKmh: $maxspeedKmh, ')
          ..write('directionDeg: $directionDeg, ')
          ..write('directionToleranceDeg: $directionToleranceDeg, ')
          ..write('roadName: $roadName, ')
          ..write('cameraType: $cameraType, ')
          ..write('regionCode: $regionCode, ')
          ..write('alertRadiusM: $alertRadiusM, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedCorridorsTable extends CachedCorridors
    with TableInfo<$CachedCorridorsTable, CachedCorridor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCorridorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _maxspeedKmhMeta = const VerificationMeta(
    'maxspeedKmh',
  );
  @override
  late final GeneratedColumn<int> maxspeedKmh = GeneratedColumn<int>(
    'maxspeed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lengthMMeta = const VerificationMeta(
    'lengthM',
  );
  @override
  late final GeneratedColumn<double> lengthM = GeneratedColumn<double>(
    'length_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionCodeMeta = const VerificationMeta(
    'regionCode',
  );
  @override
  late final GeneratedColumn<String> regionCode = GeneratedColumn<String>(
    'region_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('bursa'),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    maxspeedKmh,
    lengthM,
    regionCode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_corridors';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCorridor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('maxspeed_kmh')) {
      context.handle(
        _maxspeedKmhMeta,
        maxspeedKmh.isAcceptableOrUnknown(
          data['maxspeed_kmh']!,
          _maxspeedKmhMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxspeedKmhMeta);
    }
    if (data.containsKey('length_m')) {
      context.handle(
        _lengthMMeta,
        lengthM.isAcceptableOrUnknown(data['length_m']!, _lengthMMeta),
      );
    } else if (isInserting) {
      context.missing(_lengthMMeta);
    }
    if (data.containsKey('region_code')) {
      context.handle(
        _regionCodeMeta,
        regionCode.isAcceptableOrUnknown(data['region_code']!, _regionCodeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCorridor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCorridor(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      maxspeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maxspeed_kmh'],
      )!,
      lengthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}length_m'],
      )!,
      regionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_code'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CachedCorridorsTable createAlias(String alias) {
    return $CachedCorridorsTable(attachedDatabase, alias);
  }
}

class CachedCorridor extends DataClass implements Insertable<CachedCorridor> {
  final int id;
  final String name;
  final int maxspeedKmh;
  final double lengthM;
  final String regionCode;
  final DateTime updatedAt;
  const CachedCorridor({
    required this.id,
    required this.name,
    required this.maxspeedKmh,
    required this.lengthM,
    required this.regionCode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['maxspeed_kmh'] = Variable<int>(maxspeedKmh);
    map['length_m'] = Variable<double>(lengthM);
    map['region_code'] = Variable<String>(regionCode);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CachedCorridorsCompanion toCompanion(bool nullToAbsent) {
    return CachedCorridorsCompanion(
      id: Value(id),
      name: Value(name),
      maxspeedKmh: Value(maxspeedKmh),
      lengthM: Value(lengthM),
      regionCode: Value(regionCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory CachedCorridor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCorridor(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      maxspeedKmh: serializer.fromJson<int>(json['maxspeedKmh']),
      lengthM: serializer.fromJson<double>(json['lengthM']),
      regionCode: serializer.fromJson<String>(json['regionCode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'maxspeedKmh': serializer.toJson<int>(maxspeedKmh),
      'lengthM': serializer.toJson<double>(lengthM),
      'regionCode': serializer.toJson<String>(regionCode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedCorridor copyWith({
    int? id,
    String? name,
    int? maxspeedKmh,
    double? lengthM,
    String? regionCode,
    DateTime? updatedAt,
  }) => CachedCorridor(
    id: id ?? this.id,
    name: name ?? this.name,
    maxspeedKmh: maxspeedKmh ?? this.maxspeedKmh,
    lengthM: lengthM ?? this.lengthM,
    regionCode: regionCode ?? this.regionCode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CachedCorridor copyWithCompanion(CachedCorridorsCompanion data) {
    return CachedCorridor(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      maxspeedKmh: data.maxspeedKmh.present
          ? data.maxspeedKmh.value
          : this.maxspeedKmh,
      lengthM: data.lengthM.present ? data.lengthM.value : this.lengthM,
      regionCode: data.regionCode.present
          ? data.regionCode.value
          : this.regionCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCorridor(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('maxspeedKmh: $maxspeedKmh, ')
          ..write('lengthM: $lengthM, ')
          ..write('regionCode: $regionCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, maxspeedKmh, lengthM, regionCode, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCorridor &&
          other.id == this.id &&
          other.name == this.name &&
          other.maxspeedKmh == this.maxspeedKmh &&
          other.lengthM == this.lengthM &&
          other.regionCode == this.regionCode &&
          other.updatedAt == this.updatedAt);
}

class CachedCorridorsCompanion extends UpdateCompanion<CachedCorridor> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> maxspeedKmh;
  final Value<double> lengthM;
  final Value<String> regionCode;
  final Value<DateTime> updatedAt;
  const CachedCorridorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.maxspeedKmh = const Value.absent(),
    this.lengthM = const Value.absent(),
    this.regionCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CachedCorridorsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int maxspeedKmh,
    required double lengthM,
    this.regionCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       maxspeedKmh = Value(maxspeedKmh),
       lengthM = Value(lengthM);
  static Insertable<CachedCorridor> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? maxspeedKmh,
    Expression<double>? lengthM,
    Expression<String>? regionCode,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (maxspeedKmh != null) 'maxspeed_kmh': maxspeedKmh,
      if (lengthM != null) 'length_m': lengthM,
      if (regionCode != null) 'region_code': regionCode,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CachedCorridorsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? maxspeedKmh,
    Value<double>? lengthM,
    Value<String>? regionCode,
    Value<DateTime>? updatedAt,
  }) {
    return CachedCorridorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      maxspeedKmh: maxspeedKmh ?? this.maxspeedKmh,
      lengthM: lengthM ?? this.lengthM,
      regionCode: regionCode ?? this.regionCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (maxspeedKmh.present) {
      map['maxspeed_kmh'] = Variable<int>(maxspeedKmh.value);
    }
    if (lengthM.present) {
      map['length_m'] = Variable<double>(lengthM.value);
    }
    if (regionCode.present) {
      map['region_code'] = Variable<String>(regionCode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCorridorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('maxspeedKmh: $maxspeedKmh, ')
          ..write('lengthM: $lengthM, ')
          ..write('regionCode: $regionCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedCorridorGatesTable extends CachedCorridorGates
    with TableInfo<$CachedCorridorGatesTable, CachedCorridorGate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCorridorGatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _corridorIdMeta = const VerificationMeta(
    'corridorId',
  );
  @override
  late final GeneratedColumn<int> corridorId = GeneratedColumn<int>(
    'corridor_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_corridors (id)',
    ),
  );
  static const VerificationMeta _gateTypeMeta = const VerificationMeta(
    'gateType',
  );
  @override
  late final GeneratedColumn<String> gateType = GeneratedColumn<String>(
    'gate_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _radiusMMeta = const VerificationMeta(
    'radiusM',
  );
  @override
  late final GeneratedColumn<double> radiusM = GeneratedColumn<double>(
    'radius_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(80),
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _directionDegMeta = const VerificationMeta(
    'directionDeg',
  );
  @override
  late final GeneratedColumn<int> directionDeg = GeneratedColumn<int>(
    'direction_deg',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    corridorId,
    gateType,
    lat,
    lon,
    radiusM,
    sequence,
    directionDeg,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_corridor_gates';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCorridorGate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('corridor_id')) {
      context.handle(
        _corridorIdMeta,
        corridorId.isAcceptableOrUnknown(data['corridor_id']!, _corridorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_corridorIdMeta);
    }
    if (data.containsKey('gate_type')) {
      context.handle(
        _gateTypeMeta,
        gateType.isAcceptableOrUnknown(data['gate_type']!, _gateTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_gateTypeMeta);
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
    if (data.containsKey('radius_m')) {
      context.handle(
        _radiusMMeta,
        radiusM.isAcceptableOrUnknown(data['radius_m']!, _radiusMMeta),
      );
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('direction_deg')) {
      context.handle(
        _directionDegMeta,
        directionDeg.isAcceptableOrUnknown(
          data['direction_deg']!,
          _directionDegMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCorridorGate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCorridorGate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      corridorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}corridor_id'],
      )!,
      gateType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gate_type'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      radiusM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_m'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      directionDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction_deg'],
      ),
    );
  }

  @override
  $CachedCorridorGatesTable createAlias(String alias) {
    return $CachedCorridorGatesTable(attachedDatabase, alias);
  }
}

class CachedCorridorGate extends DataClass
    implements Insertable<CachedCorridorGate> {
  final int id;
  final int corridorId;
  final String gateType;
  final double lat;
  final double lon;
  final double radiusM;
  final int sequence;
  final int? directionDeg;
  const CachedCorridorGate({
    required this.id,
    required this.corridorId,
    required this.gateType,
    required this.lat,
    required this.lon,
    required this.radiusM,
    required this.sequence,
    this.directionDeg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['corridor_id'] = Variable<int>(corridorId);
    map['gate_type'] = Variable<String>(gateType);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['radius_m'] = Variable<double>(radiusM);
    map['sequence'] = Variable<int>(sequence);
    if (!nullToAbsent || directionDeg != null) {
      map['direction_deg'] = Variable<int>(directionDeg);
    }
    return map;
  }

  CachedCorridorGatesCompanion toCompanion(bool nullToAbsent) {
    return CachedCorridorGatesCompanion(
      id: Value(id),
      corridorId: Value(corridorId),
      gateType: Value(gateType),
      lat: Value(lat),
      lon: Value(lon),
      radiusM: Value(radiusM),
      sequence: Value(sequence),
      directionDeg: directionDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(directionDeg),
    );
  }

  factory CachedCorridorGate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCorridorGate(
      id: serializer.fromJson<int>(json['id']),
      corridorId: serializer.fromJson<int>(json['corridorId']),
      gateType: serializer.fromJson<String>(json['gateType']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      radiusM: serializer.fromJson<double>(json['radiusM']),
      sequence: serializer.fromJson<int>(json['sequence']),
      directionDeg: serializer.fromJson<int?>(json['directionDeg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'corridorId': serializer.toJson<int>(corridorId),
      'gateType': serializer.toJson<String>(gateType),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'radiusM': serializer.toJson<double>(radiusM),
      'sequence': serializer.toJson<int>(sequence),
      'directionDeg': serializer.toJson<int?>(directionDeg),
    };
  }

  CachedCorridorGate copyWith({
    int? id,
    int? corridorId,
    String? gateType,
    double? lat,
    double? lon,
    double? radiusM,
    int? sequence,
    Value<int?> directionDeg = const Value.absent(),
  }) => CachedCorridorGate(
    id: id ?? this.id,
    corridorId: corridorId ?? this.corridorId,
    gateType: gateType ?? this.gateType,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    radiusM: radiusM ?? this.radiusM,
    sequence: sequence ?? this.sequence,
    directionDeg: directionDeg.present ? directionDeg.value : this.directionDeg,
  );
  CachedCorridorGate copyWithCompanion(CachedCorridorGatesCompanion data) {
    return CachedCorridorGate(
      id: data.id.present ? data.id.value : this.id,
      corridorId: data.corridorId.present
          ? data.corridorId.value
          : this.corridorId,
      gateType: data.gateType.present ? data.gateType.value : this.gateType,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      radiusM: data.radiusM.present ? data.radiusM.value : this.radiusM,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      directionDeg: data.directionDeg.present
          ? data.directionDeg.value
          : this.directionDeg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCorridorGate(')
          ..write('id: $id, ')
          ..write('corridorId: $corridorId, ')
          ..write('gateType: $gateType, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('radiusM: $radiusM, ')
          ..write('sequence: $sequence, ')
          ..write('directionDeg: $directionDeg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    corridorId,
    gateType,
    lat,
    lon,
    radiusM,
    sequence,
    directionDeg,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCorridorGate &&
          other.id == this.id &&
          other.corridorId == this.corridorId &&
          other.gateType == this.gateType &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.radiusM == this.radiusM &&
          other.sequence == this.sequence &&
          other.directionDeg == this.directionDeg);
}

class CachedCorridorGatesCompanion extends UpdateCompanion<CachedCorridorGate> {
  final Value<int> id;
  final Value<int> corridorId;
  final Value<String> gateType;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double> radiusM;
  final Value<int> sequence;
  final Value<int?> directionDeg;
  const CachedCorridorGatesCompanion({
    this.id = const Value.absent(),
    this.corridorId = const Value.absent(),
    this.gateType = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.radiusM = const Value.absent(),
    this.sequence = const Value.absent(),
    this.directionDeg = const Value.absent(),
  });
  CachedCorridorGatesCompanion.insert({
    this.id = const Value.absent(),
    required int corridorId,
    required String gateType,
    required double lat,
    required double lon,
    this.radiusM = const Value.absent(),
    this.sequence = const Value.absent(),
    this.directionDeg = const Value.absent(),
  }) : corridorId = Value(corridorId),
       gateType = Value(gateType),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<CachedCorridorGate> custom({
    Expression<int>? id,
    Expression<int>? corridorId,
    Expression<String>? gateType,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? radiusM,
    Expression<int>? sequence,
    Expression<int>? directionDeg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (corridorId != null) 'corridor_id': corridorId,
      if (gateType != null) 'gate_type': gateType,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (radiusM != null) 'radius_m': radiusM,
      if (sequence != null) 'sequence': sequence,
      if (directionDeg != null) 'direction_deg': directionDeg,
    });
  }

  CachedCorridorGatesCompanion copyWith({
    Value<int>? id,
    Value<int>? corridorId,
    Value<String>? gateType,
    Value<double>? lat,
    Value<double>? lon,
    Value<double>? radiusM,
    Value<int>? sequence,
    Value<int?>? directionDeg,
  }) {
    return CachedCorridorGatesCompanion(
      id: id ?? this.id,
      corridorId: corridorId ?? this.corridorId,
      gateType: gateType ?? this.gateType,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      radiusM: radiusM ?? this.radiusM,
      sequence: sequence ?? this.sequence,
      directionDeg: directionDeg ?? this.directionDeg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (corridorId.present) {
      map['corridor_id'] = Variable<int>(corridorId.value);
    }
    if (gateType.present) {
      map['gate_type'] = Variable<String>(gateType.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (radiusM.present) {
      map['radius_m'] = Variable<double>(radiusM.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (directionDeg.present) {
      map['direction_deg'] = Variable<int>(directionDeg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCorridorGatesCompanion(')
          ..write('id: $id, ')
          ..write('corridorId: $corridorId, ')
          ..write('gateType: $gateType, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('radiusM: $radiusM, ')
          ..write('sequence: $sequence, ')
          ..write('directionDeg: $directionDeg')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedCamerasTable cachedCameras = $CachedCamerasTable(this);
  late final $CachedCorridorsTable cachedCorridors = $CachedCorridorsTable(
    this,
  );
  late final $CachedCorridorGatesTable cachedCorridorGates =
      $CachedCorridorGatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedCameras,
    cachedCorridors,
    cachedCorridorGates,
  ];
}

typedef $$CachedCamerasTableCreateCompanionBuilder =
    CachedCamerasCompanion Function({
      Value<int> id,
      required double lat,
      required double lon,
      Value<int?> maxspeedKmh,
      Value<int?> directionDeg,
      Value<int> directionToleranceDeg,
      Value<String?> roadName,
      Value<String> cameraType,
      Value<String> regionCode,
      Value<double> alertRadiusM,
      Value<DateTime> updatedAt,
    });
typedef $$CachedCamerasTableUpdateCompanionBuilder =
    CachedCamerasCompanion Function({
      Value<int> id,
      Value<double> lat,
      Value<double> lon,
      Value<int?> maxspeedKmh,
      Value<int?> directionDeg,
      Value<int> directionToleranceDeg,
      Value<String?> roadName,
      Value<String> cameraType,
      Value<String> regionCode,
      Value<double> alertRadiusM,
      Value<DateTime> updatedAt,
    });

class $$CachedCamerasTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCamerasTable> {
  $$CachedCamerasTableFilterComposer({
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

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxspeedKmh => $composableBuilder(
    column: $table.maxspeedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get directionDeg => $composableBuilder(
    column: $table.directionDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get directionToleranceDeg => $composableBuilder(
    column: $table.directionToleranceDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roadName => $composableBuilder(
    column: $table.roadName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cameraType => $composableBuilder(
    column: $table.cameraType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alertRadiusM => $composableBuilder(
    column: $table.alertRadiusM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCamerasTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCamerasTable> {
  $$CachedCamerasTableOrderingComposer({
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

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxspeedKmh => $composableBuilder(
    column: $table.maxspeedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get directionDeg => $composableBuilder(
    column: $table.directionDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get directionToleranceDeg => $composableBuilder(
    column: $table.directionToleranceDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roadName => $composableBuilder(
    column: $table.roadName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cameraType => $composableBuilder(
    column: $table.cameraType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alertRadiusM => $composableBuilder(
    column: $table.alertRadiusM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCamerasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCamerasTable> {
  $$CachedCamerasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<int> get maxspeedKmh => $composableBuilder(
    column: $table.maxspeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<int> get directionDeg => $composableBuilder(
    column: $table.directionDeg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get directionToleranceDeg => $composableBuilder(
    column: $table.directionToleranceDeg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roadName =>
      $composableBuilder(column: $table.roadName, builder: (column) => column);

  GeneratedColumn<String> get cameraType => $composableBuilder(
    column: $table.cameraType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get alertRadiusM => $composableBuilder(
    column: $table.alertRadiusM,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CachedCamerasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCamerasTable,
          CachedCamera,
          $$CachedCamerasTableFilterComposer,
          $$CachedCamerasTableOrderingComposer,
          $$CachedCamerasTableAnnotationComposer,
          $$CachedCamerasTableCreateCompanionBuilder,
          $$CachedCamerasTableUpdateCompanionBuilder,
          (
            CachedCamera,
            BaseReferences<_$AppDatabase, $CachedCamerasTable, CachedCamera>,
          ),
          CachedCamera,
          PrefetchHooks Function()
        > {
  $$CachedCamerasTableTableManager(_$AppDatabase db, $CachedCamerasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCamerasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCamerasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCamerasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<int?> maxspeedKmh = const Value.absent(),
                Value<int?> directionDeg = const Value.absent(),
                Value<int> directionToleranceDeg = const Value.absent(),
                Value<String?> roadName = const Value.absent(),
                Value<String> cameraType = const Value.absent(),
                Value<String> regionCode = const Value.absent(),
                Value<double> alertRadiusM = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CachedCamerasCompanion(
                id: id,
                lat: lat,
                lon: lon,
                maxspeedKmh: maxspeedKmh,
                directionDeg: directionDeg,
                directionToleranceDeg: directionToleranceDeg,
                roadName: roadName,
                cameraType: cameraType,
                regionCode: regionCode,
                alertRadiusM: alertRadiusM,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double lat,
                required double lon,
                Value<int?> maxspeedKmh = const Value.absent(),
                Value<int?> directionDeg = const Value.absent(),
                Value<int> directionToleranceDeg = const Value.absent(),
                Value<String?> roadName = const Value.absent(),
                Value<String> cameraType = const Value.absent(),
                Value<String> regionCode = const Value.absent(),
                Value<double> alertRadiusM = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CachedCamerasCompanion.insert(
                id: id,
                lat: lat,
                lon: lon,
                maxspeedKmh: maxspeedKmh,
                directionDeg: directionDeg,
                directionToleranceDeg: directionToleranceDeg,
                roadName: roadName,
                cameraType: cameraType,
                regionCode: regionCode,
                alertRadiusM: alertRadiusM,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCamerasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCamerasTable,
      CachedCamera,
      $$CachedCamerasTableFilterComposer,
      $$CachedCamerasTableOrderingComposer,
      $$CachedCamerasTableAnnotationComposer,
      $$CachedCamerasTableCreateCompanionBuilder,
      $$CachedCamerasTableUpdateCompanionBuilder,
      (
        CachedCamera,
        BaseReferences<_$AppDatabase, $CachedCamerasTable, CachedCamera>,
      ),
      CachedCamera,
      PrefetchHooks Function()
    >;
typedef $$CachedCorridorsTableCreateCompanionBuilder =
    CachedCorridorsCompanion Function({
      Value<int> id,
      required String name,
      required int maxspeedKmh,
      required double lengthM,
      Value<String> regionCode,
      Value<DateTime> updatedAt,
    });
typedef $$CachedCorridorsTableUpdateCompanionBuilder =
    CachedCorridorsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> maxspeedKmh,
      Value<double> lengthM,
      Value<String> regionCode,
      Value<DateTime> updatedAt,
    });

final class $$CachedCorridorsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CachedCorridorsTable, CachedCorridor> {
  $$CachedCorridorsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CachedCorridorGatesTable,
    List<CachedCorridorGate>
  >
  _cachedCorridorGatesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedCorridorGates,
        aliasName: $_aliasNameGenerator(
          db.cachedCorridors.id,
          db.cachedCorridorGates.corridorId,
        ),
      );

  $$CachedCorridorGatesTableProcessedTableManager get cachedCorridorGatesRefs {
    final manager = $$CachedCorridorGatesTableTableManager(
      $_db,
      $_db.cachedCorridorGates,
    ).filter((f) => f.corridorId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedCorridorGatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedCorridorsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCorridorsTable> {
  $$CachedCorridorsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxspeedKmh => $composableBuilder(
    column: $table.maxspeedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lengthM => $composableBuilder(
    column: $table.lengthM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedCorridorGatesRefs(
    Expression<bool> Function($$CachedCorridorGatesTableFilterComposer f) f,
  ) {
    final $$CachedCorridorGatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedCorridorGates,
      getReferencedColumn: (t) => t.corridorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedCorridorGatesTableFilterComposer(
            $db: $db,
            $table: $db.cachedCorridorGates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedCorridorsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCorridorsTable> {
  $$CachedCorridorsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxspeedKmh => $composableBuilder(
    column: $table.maxspeedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lengthM => $composableBuilder(
    column: $table.lengthM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCorridorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCorridorsTable> {
  $$CachedCorridorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get maxspeedKmh => $composableBuilder(
    column: $table.maxspeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lengthM =>
      $composableBuilder(column: $table.lengthM, builder: (column) => column);

  GeneratedColumn<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> cachedCorridorGatesRefs<T extends Object>(
    Expression<T> Function($$CachedCorridorGatesTableAnnotationComposer a) f,
  ) {
    final $$CachedCorridorGatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedCorridorGates,
          getReferencedColumn: (t) => t.corridorId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedCorridorGatesTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedCorridorGates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedCorridorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCorridorsTable,
          CachedCorridor,
          $$CachedCorridorsTableFilterComposer,
          $$CachedCorridorsTableOrderingComposer,
          $$CachedCorridorsTableAnnotationComposer,
          $$CachedCorridorsTableCreateCompanionBuilder,
          $$CachedCorridorsTableUpdateCompanionBuilder,
          (CachedCorridor, $$CachedCorridorsTableReferences),
          CachedCorridor,
          PrefetchHooks Function({bool cachedCorridorGatesRefs})
        > {
  $$CachedCorridorsTableTableManager(
    _$AppDatabase db,
    $CachedCorridorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCorridorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCorridorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCorridorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> maxspeedKmh = const Value.absent(),
                Value<double> lengthM = const Value.absent(),
                Value<String> regionCode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CachedCorridorsCompanion(
                id: id,
                name: name,
                maxspeedKmh: maxspeedKmh,
                lengthM: lengthM,
                regionCode: regionCode,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int maxspeedKmh,
                required double lengthM,
                Value<String> regionCode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CachedCorridorsCompanion.insert(
                id: id,
                name: name,
                maxspeedKmh: maxspeedKmh,
                lengthM: lengthM,
                regionCode: regionCode,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedCorridorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cachedCorridorGatesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cachedCorridorGatesRefs) db.cachedCorridorGates,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cachedCorridorGatesRefs)
                    await $_getPrefetchedData<
                      CachedCorridor,
                      $CachedCorridorsTable,
                      CachedCorridorGate
                    >(
                      currentTable: table,
                      referencedTable: $$CachedCorridorsTableReferences
                          ._cachedCorridorGatesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CachedCorridorsTableReferences(
                            db,
                            table,
                            p0,
                          ).cachedCorridorGatesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.corridorId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CachedCorridorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCorridorsTable,
      CachedCorridor,
      $$CachedCorridorsTableFilterComposer,
      $$CachedCorridorsTableOrderingComposer,
      $$CachedCorridorsTableAnnotationComposer,
      $$CachedCorridorsTableCreateCompanionBuilder,
      $$CachedCorridorsTableUpdateCompanionBuilder,
      (CachedCorridor, $$CachedCorridorsTableReferences),
      CachedCorridor,
      PrefetchHooks Function({bool cachedCorridorGatesRefs})
    >;
typedef $$CachedCorridorGatesTableCreateCompanionBuilder =
    CachedCorridorGatesCompanion Function({
      Value<int> id,
      required int corridorId,
      required String gateType,
      required double lat,
      required double lon,
      Value<double> radiusM,
      Value<int> sequence,
      Value<int?> directionDeg,
    });
typedef $$CachedCorridorGatesTableUpdateCompanionBuilder =
    CachedCorridorGatesCompanion Function({
      Value<int> id,
      Value<int> corridorId,
      Value<String> gateType,
      Value<double> lat,
      Value<double> lon,
      Value<double> radiusM,
      Value<int> sequence,
      Value<int?> directionDeg,
    });

final class $$CachedCorridorGatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedCorridorGatesTable,
          CachedCorridorGate
        > {
  $$CachedCorridorGatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedCorridorsTable _corridorIdTable(_$AppDatabase db) =>
      db.cachedCorridors.createAlias(
        $_aliasNameGenerator(
          db.cachedCorridorGates.corridorId,
          db.cachedCorridors.id,
        ),
      );

  $$CachedCorridorsTableProcessedTableManager get corridorId {
    final $_column = $_itemColumn<int>('corridor_id')!;

    final manager = $$CachedCorridorsTableTableManager(
      $_db,
      $_db.cachedCorridors,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_corridorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedCorridorGatesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCorridorGatesTable> {
  $$CachedCorridorGatesTableFilterComposer({
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

  ColumnFilters<String> get gateType => $composableBuilder(
    column: $table.gateType,
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

  ColumnFilters<double> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get directionDeg => $composableBuilder(
    column: $table.directionDeg,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedCorridorsTableFilterComposer get corridorId {
    final $$CachedCorridorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.corridorId,
      referencedTable: $db.cachedCorridors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedCorridorsTableFilterComposer(
            $db: $db,
            $table: $db.cachedCorridors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedCorridorGatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCorridorGatesTable> {
  $$CachedCorridorGatesTableOrderingComposer({
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

  ColumnOrderings<String> get gateType => $composableBuilder(
    column: $table.gateType,
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

  ColumnOrderings<double> get radiusM => $composableBuilder(
    column: $table.radiusM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get directionDeg => $composableBuilder(
    column: $table.directionDeg,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedCorridorsTableOrderingComposer get corridorId {
    final $$CachedCorridorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.corridorId,
      referencedTable: $db.cachedCorridors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedCorridorsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedCorridors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedCorridorGatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCorridorGatesTable> {
  $$CachedCorridorGatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gateType =>
      $composableBuilder(column: $table.gateType, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get radiusM =>
      $composableBuilder(column: $table.radiusM, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<int> get directionDeg => $composableBuilder(
    column: $table.directionDeg,
    builder: (column) => column,
  );

  $$CachedCorridorsTableAnnotationComposer get corridorId {
    final $$CachedCorridorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.corridorId,
      referencedTable: $db.cachedCorridors,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedCorridorsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedCorridors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedCorridorGatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCorridorGatesTable,
          CachedCorridorGate,
          $$CachedCorridorGatesTableFilterComposer,
          $$CachedCorridorGatesTableOrderingComposer,
          $$CachedCorridorGatesTableAnnotationComposer,
          $$CachedCorridorGatesTableCreateCompanionBuilder,
          $$CachedCorridorGatesTableUpdateCompanionBuilder,
          (CachedCorridorGate, $$CachedCorridorGatesTableReferences),
          CachedCorridorGate,
          PrefetchHooks Function({bool corridorId})
        > {
  $$CachedCorridorGatesTableTableManager(
    _$AppDatabase db,
    $CachedCorridorGatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCorridorGatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCorridorGatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedCorridorGatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> corridorId = const Value.absent(),
                Value<String> gateType = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double> radiusM = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<int?> directionDeg = const Value.absent(),
              }) => CachedCorridorGatesCompanion(
                id: id,
                corridorId: corridorId,
                gateType: gateType,
                lat: lat,
                lon: lon,
                radiusM: radiusM,
                sequence: sequence,
                directionDeg: directionDeg,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int corridorId,
                required String gateType,
                required double lat,
                required double lon,
                Value<double> radiusM = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<int?> directionDeg = const Value.absent(),
              }) => CachedCorridorGatesCompanion.insert(
                id: id,
                corridorId: corridorId,
                gateType: gateType,
                lat: lat,
                lon: lon,
                radiusM: radiusM,
                sequence: sequence,
                directionDeg: directionDeg,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedCorridorGatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({corridorId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (corridorId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.corridorId,
                                referencedTable:
                                    $$CachedCorridorGatesTableReferences
                                        ._corridorIdTable(db),
                                referencedColumn:
                                    $$CachedCorridorGatesTableReferences
                                        ._corridorIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedCorridorGatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCorridorGatesTable,
      CachedCorridorGate,
      $$CachedCorridorGatesTableFilterComposer,
      $$CachedCorridorGatesTableOrderingComposer,
      $$CachedCorridorGatesTableAnnotationComposer,
      $$CachedCorridorGatesTableCreateCompanionBuilder,
      $$CachedCorridorGatesTableUpdateCompanionBuilder,
      (CachedCorridorGate, $$CachedCorridorGatesTableReferences),
      CachedCorridorGate,
      PrefetchHooks Function({bool corridorId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedCamerasTableTableManager get cachedCameras =>
      $$CachedCamerasTableTableManager(_db, _db.cachedCameras);
  $$CachedCorridorsTableTableManager get cachedCorridors =>
      $$CachedCorridorsTableTableManager(_db, _db.cachedCorridors);
  $$CachedCorridorGatesTableTableManager get cachedCorridorGates =>
      $$CachedCorridorGatesTableTableManager(_db, _db.cachedCorridorGates);
}
