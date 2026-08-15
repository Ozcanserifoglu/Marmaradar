import 'package:radar_alert/features/amenities/amenity_models.dart';

class AmenitySessionCache {
  final Map<String, CachedAmenityCell> _byCell = {};

  bool hasCell(String cellKey) => _byCell.containsKey(cellKey);

  CachedAmenityCell? get(String cellKey) => _byCell[cellKey];

  void putCell(CachedAmenityCell entry) {
    _byCell[entry.cellKey] = entry;
  }

  void putPlaces(Iterable<AmenityPlace> places, {DateTime? fetchedAt}) {
    final now = fetchedAt ?? DateTime.now();
    final byCell = <String, List<AmenityPlace>>{};
    for (final p in places) {
      if (p.placeId.isEmpty || p.cellKey.isEmpty) continue;
      byCell.putIfAbsent(p.cellKey, () => []).add(p);
    }
    for (final entry in byCell.entries) {
      final existing = _byCell[entry.key]?.places ?? const <AmenityPlace>[];
      final merged = _dedupeByPlaceId([...existing, ...entry.value]);
      _byCell[entry.key] = CachedAmenityCell(
        cellKey: entry.key,
        places: merged,
        fetchedAt: now,
      );
    }
  }

  void markFetched(Iterable<String> cellKeys, {DateTime? fetchedAt}) {
    final now = fetchedAt ?? DateTime.now();
    for (final key in cellKeys) {
      if (_byCell.containsKey(key)) continue;
      _byCell[key] = CachedAmenityCell(
        cellKey: key,
        places: const [],
        fetchedAt: now,
      );
    }
  }

  List<AmenityPlace> allPlaces() {
    final out = <AmenityPlace>[];
    final seen = <String>{};
    for (final cell in _byCell.values) {
      for (final p in cell.places) {
        if (!seen.add(p.placeId)) continue;
        out.add(p);
      }
    }
    return out;
  }

  void clear() => _byCell.clear();

  static List<AmenityPlace> _dedupeByPlaceId(List<AmenityPlace> places) {
    final seen = <String>{};
    final out = <AmenityPlace>[];
    for (final p in places) {
      if (!seen.add(p.placeId)) continue;
      out.add(p);
    }
    return out;
  }
}
