import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class CachedCameras extends Table {
  IntColumn get id => integer()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  IntColumn get maxspeedKmh => integer().nullable()();
  IntColumn get directionDeg => integer().nullable()();
  IntColumn get directionToleranceDeg => integer().withDefault(const Constant(35))();
  TextColumn get roadName => text().nullable()();
  TextColumn get cameraType => text().withDefault(const Constant('fixed'))();
  TextColumn get regionCode => text().withDefault(const Constant('bursa'))();
  RealColumn get alertRadiusM => real().withDefault(const Constant(1000))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCorridors extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get maxspeedKmh => integer()();
  RealColumn get lengthM => real()();
  TextColumn get regionCode => text().withDefault(const Constant('bursa'))();

  /// Road-following geometry as a Google encoded polyline (precision 5).
  /// Null for corridors the server hasn't enriched with route geometry.
  TextColumn get polyline => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCorridorGates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get corridorId => integer().references(CachedCorridors, #id)();
  TextColumn get gateType => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get radiusM => real().withDefault(const Constant(80))();
  IntColumn get sequence => integer().withDefault(const Constant(0))();
  IntColumn get directionDeg => integer().nullable()();
}

/// Local drive session awaiting upload (or already uploaded).
class LocalDrives extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  /// recording | pending_upload | uploaded
  TextColumn get status => text()();
  TextColumn get remoteId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalDrivePoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get driveId => text().references(LocalDrives, #id)();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get speedMps => real()();
  DateTimeColumn get recordedAt => dateTime()();
  IntColumn get sequence => integer()();
}

@DriftDatabase(tables: [
  CachedCameras,
  CachedCorridors,
  CachedCorridorGates,
  LocalDrives,
  LocalDrivePoints,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(cachedCorridors, cachedCorridors.polyline);
          }
          if (from < 3) {
            await m.createTable(localDrives);
            await m.createTable(localDrivePoints);
          }
        },
      );

  Future<List<CachedCamera>> camerasNear(
    double lat,
    double lon,
    double radiusM,
  ) async {
    final all = await select(cachedCameras).get();
    return all.where((c) {
      final dLat = (c.lat - lat) * 111320;
      final dLon = (c.lon - lon) * 111320 * math.cos(lat * math.pi / 180);
      return (dLat * dLat + dLon * dLon) <= radiusM * radiusM;
    }).toList();
  }

  Future<List<CachedCamera>> allCameras() => select(cachedCameras).get();

  Future<List<CachedCorridor>> allCorridors() => select(cachedCorridors).get();

  Future<List<CachedCorridorGate>> gatesFor(int corridorId) {
    return (select(cachedCorridorGates)
          ..where((g) => g.corridorId.equals(corridorId)))
        .get();
  }

  Future<void> upsertCamera(CachedCamerasCompanion row) async {
    await into(cachedCameras).insertOnConflictUpdate(row);
  }

  Future<void> upsertCorridor(CachedCorridorsCompanion row) async {
    await into(cachedCorridors).insertOnConflictUpdate(row);
  }

  Future<void> replaceGatesForCorridor(
    int corridorId,
    List<CachedCorridorGatesCompanion> gates,
  ) async {
    await (delete(cachedCorridorGates)
          ..where((g) => g.corridorId.equals(corridorId)))
        .go();
    for (final gate in gates) {
      await into(cachedCorridorGates).insert(gate);
    }
  }

  Future<void> insertDrive(LocalDrivesCompanion row) async {
    await into(localDrives).insert(row);
  }

  Future<void> updateDrive(LocalDrivesCompanion row) async {
    await (update(localDrives)..where((d) => d.id.equals(row.id.value)))
        .write(row);
  }

  Future<void> insertDrivePoint(LocalDrivePointsCompanion row) async {
    await into(localDrivePoints).insert(row);
  }

  Future<List<LocalDrivePoint>> pointsForDrive(String driveId) {
    return (select(localDrivePoints)
          ..where((p) => p.driveId.equals(driveId))
          ..orderBy([(p) => OrderingTerm.asc(p.sequence)]))
        .get();
  }

  Future<int> pointCountForDrive(String driveId) async {
    final count = localDrivePoints.id.count();
    final query = selectOnly(localDrivePoints)
      ..addColumns([count])
      ..where(localDrivePoints.driveId.equals(driveId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> deleteDriveCascade(String driveId) async {
    await (delete(localDrivePoints)..where((p) => p.driveId.equals(driveId)))
        .go();
    await (delete(localDrives)..where((d) => d.id.equals(driveId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'radar_alert.sqlite'));
    return NativeDatabase(file);
  });
}
