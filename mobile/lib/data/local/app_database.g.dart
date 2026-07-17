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
  static const VerificationMeta _polylineMeta = const VerificationMeta(
    'polyline',
  );
  @override
  late final GeneratedColumn<String> polyline = GeneratedColumn<String>(
    'polyline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    polyline,
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
    if (data.containsKey('polyline')) {
      context.handle(
        _polylineMeta,
        polyline.isAcceptableOrUnknown(data['polyline']!, _polylineMeta),
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
      polyline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}polyline'],
      ),
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

  /// Road-following geometry as a Google encoded polyline (precision 5).
  /// Null for corridors the server hasn't enriched with route geometry.
  final String? polyline;
  final DateTime updatedAt;
  const CachedCorridor({
    required this.id,
    required this.name,
    required this.maxspeedKmh,
    required this.lengthM,
    required this.regionCode,
    this.polyline,
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
    if (!nullToAbsent || polyline != null) {
      map['polyline'] = Variable<String>(polyline);
    }
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
      polyline: polyline == null && nullToAbsent
          ? const Value.absent()
          : Value(polyline),
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
      polyline: serializer.fromJson<String?>(json['polyline']),
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
      'polyline': serializer.toJson<String?>(polyline),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CachedCorridor copyWith({
    int? id,
    String? name,
    int? maxspeedKmh,
    double? lengthM,
    String? regionCode,
    Value<String?> polyline = const Value.absent(),
    DateTime? updatedAt,
  }) => CachedCorridor(
    id: id ?? this.id,
    name: name ?? this.name,
    maxspeedKmh: maxspeedKmh ?? this.maxspeedKmh,
    lengthM: lengthM ?? this.lengthM,
    regionCode: regionCode ?? this.regionCode,
    polyline: polyline.present ? polyline.value : this.polyline,
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
      polyline: data.polyline.present ? data.polyline.value : this.polyline,
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
          ..write('polyline: $polyline, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    maxspeedKmh,
    lengthM,
    regionCode,
    polyline,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCorridor &&
          other.id == this.id &&
          other.name == this.name &&
          other.maxspeedKmh == this.maxspeedKmh &&
          other.lengthM == this.lengthM &&
          other.regionCode == this.regionCode &&
          other.polyline == this.polyline &&
          other.updatedAt == this.updatedAt);
}

class CachedCorridorsCompanion extends UpdateCompanion<CachedCorridor> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> maxspeedKmh;
  final Value<double> lengthM;
  final Value<String> regionCode;
  final Value<String?> polyline;
  final Value<DateTime> updatedAt;
  const CachedCorridorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.maxspeedKmh = const Value.absent(),
    this.lengthM = const Value.absent(),
    this.regionCode = const Value.absent(),
    this.polyline = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CachedCorridorsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int maxspeedKmh,
    required double lengthM,
    this.regionCode = const Value.absent(),
    this.polyline = const Value.absent(),
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
    Expression<String>? polyline,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (maxspeedKmh != null) 'maxspeed_kmh': maxspeedKmh,
      if (lengthM != null) 'length_m': lengthM,
      if (regionCode != null) 'region_code': regionCode,
      if (polyline != null) 'polyline': polyline,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CachedCorridorsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? maxspeedKmh,
    Value<double>? lengthM,
    Value<String>? regionCode,
    Value<String?>? polyline,
    Value<DateTime>? updatedAt,
  }) {
    return CachedCorridorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      maxspeedKmh: maxspeedKmh ?? this.maxspeedKmh,
      lengthM: lengthM ?? this.lengthM,
      regionCode: regionCode ?? this.regionCode,
      polyline: polyline ?? this.polyline,
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
    if (polyline.present) {
      map['polyline'] = Variable<String>(polyline.value);
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
          ..write('polyline: $polyline, ')
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

class $LocalDrivesTable extends LocalDrives
    with TableInfo<$LocalDrivesTable, LocalDrive> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDrivesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    status,
    remoteId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_drives';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDrive> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDrive map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDrive(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
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
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
    );
  }

  @override
  $LocalDrivesTable createAlias(String alias) {
    return $LocalDrivesTable(attachedDatabase, alias);
  }
}

class LocalDrive extends DataClass implements Insertable<LocalDrive> {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// recording | pending_upload | uploaded
  final String status;
  final String? remoteId;
  const LocalDrive({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.status,
    this.remoteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    return map;
  }

  LocalDrivesCompanion toCompanion(bool nullToAbsent) {
    return LocalDrivesCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      status: Value(status),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
    );
  }

  factory LocalDrive.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDrive(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      status: serializer.fromJson<String>(json['status']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'status': serializer.toJson<String>(status),
      'remoteId': serializer.toJson<String?>(remoteId),
    };
  }

  LocalDrive copyWith({
    String? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? status,
    Value<String?> remoteId = const Value.absent(),
  }) => LocalDrive(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    status: status ?? this.status,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
  );
  LocalDrive copyWithCompanion(LocalDrivesCompanion data) {
    return LocalDrive(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      status: data.status.present ? data.status.value : this.status,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDrive(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('remoteId: $remoteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startedAt, endedAt, status, remoteId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDrive &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.status == this.status &&
          other.remoteId == this.remoteId);
}

class LocalDrivesCompanion extends UpdateCompanion<LocalDrive> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> status;
  final Value<String?> remoteId;
  final Value<int> rowid;
  const LocalDrivesCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDrivesCompanion.insert({
    required String id,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required String status,
    this.remoteId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       status = Value(status);
  static Insertable<LocalDrive> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? status,
    Expression<String>? remoteId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
      if (remoteId != null) 'remote_id': remoteId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDrivesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? status,
    Value<String?>? remoteId,
    Value<int>? rowid,
  }) {
    return LocalDrivesCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      remoteId: remoteId ?? this.remoteId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDrivesCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('remoteId: $remoteId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDrivePointsTable extends LocalDrivePoints
    with TableInfo<$LocalDrivePointsTable, LocalDrivePoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDrivePointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _driveIdMeta = const VerificationMeta(
    'driveId',
  );
  @override
  late final GeneratedColumn<String> driveId = GeneratedColumn<String>(
    'drive_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_drives (id)',
    ),
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
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    driveId,
    lat,
    lon,
    speedMps,
    recordedAt,
    sequence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_drive_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDrivePoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('drive_id')) {
      context.handle(
        _driveIdMeta,
        driveId.isAcceptableOrUnknown(data['drive_id']!, _driveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_driveIdMeta);
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
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    } else if (isInserting) {
      context.missing(_speedMpsMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDrivePoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDrivePoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      driveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drive_id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
    );
  }

  @override
  $LocalDrivePointsTable createAlias(String alias) {
    return $LocalDrivePointsTable(attachedDatabase, alias);
  }
}

class LocalDrivePoint extends DataClass implements Insertable<LocalDrivePoint> {
  final int id;
  final String driveId;
  final double lat;
  final double lon;
  final double speedMps;
  final DateTime recordedAt;
  final int sequence;
  const LocalDrivePoint({
    required this.id,
    required this.driveId,
    required this.lat,
    required this.lon,
    required this.speedMps,
    required this.recordedAt,
    required this.sequence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['drive_id'] = Variable<String>(driveId);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['speed_mps'] = Variable<double>(speedMps);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['sequence'] = Variable<int>(sequence);
    return map;
  }

  LocalDrivePointsCompanion toCompanion(bool nullToAbsent) {
    return LocalDrivePointsCompanion(
      id: Value(id),
      driveId: Value(driveId),
      lat: Value(lat),
      lon: Value(lon),
      speedMps: Value(speedMps),
      recordedAt: Value(recordedAt),
      sequence: Value(sequence),
    );
  }

  factory LocalDrivePoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDrivePoint(
      id: serializer.fromJson<int>(json['id']),
      driveId: serializer.fromJson<String>(json['driveId']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      speedMps: serializer.fromJson<double>(json['speedMps']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      sequence: serializer.fromJson<int>(json['sequence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'driveId': serializer.toJson<String>(driveId),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'speedMps': serializer.toJson<double>(speedMps),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'sequence': serializer.toJson<int>(sequence),
    };
  }

  LocalDrivePoint copyWith({
    int? id,
    String? driveId,
    double? lat,
    double? lon,
    double? speedMps,
    DateTime? recordedAt,
    int? sequence,
  }) => LocalDrivePoint(
    id: id ?? this.id,
    driveId: driveId ?? this.driveId,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    speedMps: speedMps ?? this.speedMps,
    recordedAt: recordedAt ?? this.recordedAt,
    sequence: sequence ?? this.sequence,
  );
  LocalDrivePoint copyWithCompanion(LocalDrivePointsCompanion data) {
    return LocalDrivePoint(
      id: data.id.present ? data.id.value : this.id,
      driveId: data.driveId.present ? data.driveId.value : this.driveId,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDrivePoint(')
          ..write('id: $id, ')
          ..write('driveId: $driveId, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('speedMps: $speedMps, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('sequence: $sequence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, driveId, lat, lon, speedMps, recordedAt, sequence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDrivePoint &&
          other.id == this.id &&
          other.driveId == this.driveId &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.speedMps == this.speedMps &&
          other.recordedAt == this.recordedAt &&
          other.sequence == this.sequence);
}

class LocalDrivePointsCompanion extends UpdateCompanion<LocalDrivePoint> {
  final Value<int> id;
  final Value<String> driveId;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double> speedMps;
  final Value<DateTime> recordedAt;
  final Value<int> sequence;
  const LocalDrivePointsCompanion({
    this.id = const Value.absent(),
    this.driveId = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.sequence = const Value.absent(),
  });
  LocalDrivePointsCompanion.insert({
    this.id = const Value.absent(),
    required String driveId,
    required double lat,
    required double lon,
    required double speedMps,
    required DateTime recordedAt,
    required int sequence,
  }) : driveId = Value(driveId),
       lat = Value(lat),
       lon = Value(lon),
       speedMps = Value(speedMps),
       recordedAt = Value(recordedAt),
       sequence = Value(sequence);
  static Insertable<LocalDrivePoint> custom({
    Expression<int>? id,
    Expression<String>? driveId,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? speedMps,
    Expression<DateTime>? recordedAt,
    Expression<int>? sequence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (driveId != null) 'drive_id': driveId,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (speedMps != null) 'speed_mps': speedMps,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (sequence != null) 'sequence': sequence,
    });
  }

  LocalDrivePointsCompanion copyWith({
    Value<int>? id,
    Value<String>? driveId,
    Value<double>? lat,
    Value<double>? lon,
    Value<double>? speedMps,
    Value<DateTime>? recordedAt,
    Value<int>? sequence,
  }) {
    return LocalDrivePointsCompanion(
      id: id ?? this.id,
      driveId: driveId ?? this.driveId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      speedMps: speedMps ?? this.speedMps,
      recordedAt: recordedAt ?? this.recordedAt,
      sequence: sequence ?? this.sequence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (driveId.present) {
      map['drive_id'] = Variable<String>(driveId.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDrivePointsCompanion(')
          ..write('id: $id, ')
          ..write('driveId: $driveId, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('speedMps: $speedMps, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('sequence: $sequence')
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
  late final $LocalDrivesTable localDrives = $LocalDrivesTable(this);
  late final $LocalDrivePointsTable localDrivePoints = $LocalDrivePointsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedCameras,
    cachedCorridors,
    cachedCorridorGates,
    localDrives,
    localDrivePoints,
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
      Value<String?> polyline,
      Value<DateTime> updatedAt,
    });
typedef $$CachedCorridorsTableUpdateCompanionBuilder =
    CachedCorridorsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> maxspeedKmh,
      Value<double> lengthM,
      Value<String> regionCode,
      Value<String?> polyline,
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

  ColumnFilters<String> get polyline => $composableBuilder(
    column: $table.polyline,
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

  ColumnOrderings<String> get polyline => $composableBuilder(
    column: $table.polyline,
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

  GeneratedColumn<String> get polyline =>
      $composableBuilder(column: $table.polyline, builder: (column) => column);

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
                Value<String?> polyline = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CachedCorridorsCompanion(
                id: id,
                name: name,
                maxspeedKmh: maxspeedKmh,
                lengthM: lengthM,
                regionCode: regionCode,
                polyline: polyline,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int maxspeedKmh,
                required double lengthM,
                Value<String> regionCode = const Value.absent(),
                Value<String?> polyline = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CachedCorridorsCompanion.insert(
                id: id,
                name: name,
                maxspeedKmh: maxspeedKmh,
                lengthM: lengthM,
                regionCode: regionCode,
                polyline: polyline,
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
typedef $$LocalDrivesTableCreateCompanionBuilder =
    LocalDrivesCompanion Function({
      required String id,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required String status,
      Value<String?> remoteId,
      Value<int> rowid,
    });
typedef $$LocalDrivesTableUpdateCompanionBuilder =
    LocalDrivesCompanion Function({
      Value<String> id,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String> status,
      Value<String?> remoteId,
      Value<int> rowid,
    });

final class $$LocalDrivesTableReferences
    extends BaseReferences<_$AppDatabase, $LocalDrivesTable, LocalDrive> {
  $$LocalDrivesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalDrivePointsTable, List<LocalDrivePoint>>
  _localDrivePointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localDrivePoints,
    aliasName: $_aliasNameGenerator(
      db.localDrives.id,
      db.localDrivePoints.driveId,
    ),
  );

  $$LocalDrivePointsTableProcessedTableManager get localDrivePointsRefs {
    final manager = $$LocalDrivePointsTableTableManager(
      $_db,
      $_db.localDrivePoints,
    ).filter((f) => f.driveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localDrivePointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalDrivesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDrivesTable> {
  $$LocalDrivesTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localDrivePointsRefs(
    Expression<bool> Function($$LocalDrivePointsTableFilterComposer f) f,
  ) {
    final $$LocalDrivePointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localDrivePoints,
      getReferencedColumn: (t) => t.driveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDrivePointsTableFilterComposer(
            $db: $db,
            $table: $db.localDrivePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalDrivesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDrivesTable> {
  $$LocalDrivesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDrivesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDrivesTable> {
  $$LocalDrivesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  Expression<T> localDrivePointsRefs<T extends Object>(
    Expression<T> Function($$LocalDrivePointsTableAnnotationComposer a) f,
  ) {
    final $$LocalDrivePointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localDrivePoints,
      getReferencedColumn: (t) => t.driveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDrivePointsTableAnnotationComposer(
            $db: $db,
            $table: $db.localDrivePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalDrivesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDrivesTable,
          LocalDrive,
          $$LocalDrivesTableFilterComposer,
          $$LocalDrivesTableOrderingComposer,
          $$LocalDrivesTableAnnotationComposer,
          $$LocalDrivesTableCreateCompanionBuilder,
          $$LocalDrivesTableUpdateCompanionBuilder,
          (LocalDrive, $$LocalDrivesTableReferences),
          LocalDrive,
          PrefetchHooks Function({bool localDrivePointsRefs})
        > {
  $$LocalDrivesTableTableManager(_$AppDatabase db, $LocalDrivesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDrivesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDrivesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDrivesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDrivesCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                remoteId: remoteId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required String status,
                Value<String?> remoteId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDrivesCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                remoteId: remoteId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalDrivesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localDrivePointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localDrivePointsRefs) db.localDrivePoints,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localDrivePointsRefs)
                    await $_getPrefetchedData<
                      LocalDrive,
                      $LocalDrivesTable,
                      LocalDrivePoint
                    >(
                      currentTable: table,
                      referencedTable: $$LocalDrivesTableReferences
                          ._localDrivePointsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalDrivesTableReferences(
                            db,
                            table,
                            p0,
                          ).localDrivePointsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.driveId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalDrivesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDrivesTable,
      LocalDrive,
      $$LocalDrivesTableFilterComposer,
      $$LocalDrivesTableOrderingComposer,
      $$LocalDrivesTableAnnotationComposer,
      $$LocalDrivesTableCreateCompanionBuilder,
      $$LocalDrivesTableUpdateCompanionBuilder,
      (LocalDrive, $$LocalDrivesTableReferences),
      LocalDrive,
      PrefetchHooks Function({bool localDrivePointsRefs})
    >;
typedef $$LocalDrivePointsTableCreateCompanionBuilder =
    LocalDrivePointsCompanion Function({
      Value<int> id,
      required String driveId,
      required double lat,
      required double lon,
      required double speedMps,
      required DateTime recordedAt,
      required int sequence,
    });
typedef $$LocalDrivePointsTableUpdateCompanionBuilder =
    LocalDrivePointsCompanion Function({
      Value<int> id,
      Value<String> driveId,
      Value<double> lat,
      Value<double> lon,
      Value<double> speedMps,
      Value<DateTime> recordedAt,
      Value<int> sequence,
    });

final class $$LocalDrivePointsTableReferences
    extends
        BaseReferences<_$AppDatabase, $LocalDrivePointsTable, LocalDrivePoint> {
  $$LocalDrivePointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalDrivesTable _driveIdTable(_$AppDatabase db) =>
      db.localDrives.createAlias(
        $_aliasNameGenerator(db.localDrivePoints.driveId, db.localDrives.id),
      );

  $$LocalDrivesTableProcessedTableManager get driveId {
    final $_column = $_itemColumn<String>('drive_id')!;

    final manager = $$LocalDrivesTableTableManager(
      $_db,
      $_db.localDrives,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_driveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalDrivePointsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDrivePointsTable> {
  $$LocalDrivePointsTableFilterComposer({
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

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalDrivesTableFilterComposer get driveId {
    final $$LocalDrivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.driveId,
      referencedTable: $db.localDrives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDrivesTableFilterComposer(
            $db: $db,
            $table: $db.localDrives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDrivePointsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDrivePointsTable> {
  $$LocalDrivePointsTableOrderingComposer({
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

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalDrivesTableOrderingComposer get driveId {
    final $$LocalDrivesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.driveId,
      referencedTable: $db.localDrives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDrivesTableOrderingComposer(
            $db: $db,
            $table: $db.localDrives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDrivePointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDrivePointsTable> {
  $$LocalDrivePointsTableAnnotationComposer({
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

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  $$LocalDrivesTableAnnotationComposer get driveId {
    final $$LocalDrivesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.driveId,
      referencedTable: $db.localDrives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDrivesTableAnnotationComposer(
            $db: $db,
            $table: $db.localDrives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDrivePointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDrivePointsTable,
          LocalDrivePoint,
          $$LocalDrivePointsTableFilterComposer,
          $$LocalDrivePointsTableOrderingComposer,
          $$LocalDrivePointsTableAnnotationComposer,
          $$LocalDrivePointsTableCreateCompanionBuilder,
          $$LocalDrivePointsTableUpdateCompanionBuilder,
          (LocalDrivePoint, $$LocalDrivePointsTableReferences),
          LocalDrivePoint,
          PrefetchHooks Function({bool driveId})
        > {
  $$LocalDrivePointsTableTableManager(
    _$AppDatabase db,
    $LocalDrivePointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDrivePointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDrivePointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDrivePointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> driveId = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double> speedMps = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> sequence = const Value.absent(),
              }) => LocalDrivePointsCompanion(
                id: id,
                driveId: driveId,
                lat: lat,
                lon: lon,
                speedMps: speedMps,
                recordedAt: recordedAt,
                sequence: sequence,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String driveId,
                required double lat,
                required double lon,
                required double speedMps,
                required DateTime recordedAt,
                required int sequence,
              }) => LocalDrivePointsCompanion.insert(
                id: id,
                driveId: driveId,
                lat: lat,
                lon: lon,
                speedMps: speedMps,
                recordedAt: recordedAt,
                sequence: sequence,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalDrivePointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({driveId = false}) {
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
                    if (driveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.driveId,
                                referencedTable:
                                    $$LocalDrivePointsTableReferences
                                        ._driveIdTable(db),
                                referencedColumn:
                                    $$LocalDrivePointsTableReferences
                                        ._driveIdTable(db)
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

typedef $$LocalDrivePointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDrivePointsTable,
      LocalDrivePoint,
      $$LocalDrivePointsTableFilterComposer,
      $$LocalDrivePointsTableOrderingComposer,
      $$LocalDrivePointsTableAnnotationComposer,
      $$LocalDrivePointsTableCreateCompanionBuilder,
      $$LocalDrivePointsTableUpdateCompanionBuilder,
      (LocalDrivePoint, $$LocalDrivePointsTableReferences),
      LocalDrivePoint,
      PrefetchHooks Function({bool driveId})
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
  $$LocalDrivesTableTableManager get localDrives =>
      $$LocalDrivesTableTableManager(_db, _db.localDrives);
  $$LocalDrivePointsTableTableManager get localDrivePoints =>
      $$LocalDrivePointsTableTableManager(_db, _db.localDrivePoints);
}
