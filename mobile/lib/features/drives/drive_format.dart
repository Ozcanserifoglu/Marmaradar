// Lightweight, dependency-free formatting helpers for drive metadata
// (the app does not depend on `intl`).

const _monthsTr = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

String _two(int v) => v.toString().padLeft(2, '0');

/// The custom name if set, otherwise the formatted start date.
String driveDisplayName(String? name, DateTime startedAt) {
  if (name != null && name.trim().isNotEmpty) return name.trim();
  return formatDriveDate(startedAt);
}

/// e.g. "20 Tem 2026, 17:05"
String formatDriveDate(DateTime dt) {
  final local = dt.toLocal();
  final month = _monthsTr[local.month - 1];
  return '${local.day} $month ${local.year}, ${_two(local.hour)}:${_two(local.minute)}';
}

/// e.g. "8 dk", "1 sa 5 dk", "45 sn"
String formatDuration(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds} sn';
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  if (hours > 0) return '$hours sa $minutes dk';
  return '$minutes dk';
}

/// e.g. "850 m", "3.2 km"
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Meters-per-second to whole km/h.
int speedKmh(double mps) => (mps * 3.6).round();
