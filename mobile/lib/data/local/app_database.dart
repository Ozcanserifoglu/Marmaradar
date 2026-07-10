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

@DriftDatabase(tables: [CachedCameras, CachedCorridors, CachedCorridorGates])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'radar_alert.sqlite'));
    return NativeDatabase(file);
  });
}
