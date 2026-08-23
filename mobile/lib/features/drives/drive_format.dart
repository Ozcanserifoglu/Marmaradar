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

String driveDisplayName(String? name, DateTime startedAt) {
  if (name != null && name.trim().isNotEmpty) return name.trim();
  return formatDriveDate(startedAt);
}

String formatDriveDate(DateTime dt) {
  final local = dt.toLocal();
  final month = _monthsTr[local.month - 1];
  return '${local.day} $month ${local.year}, ${_two(local.hour)}:${_two(local.minute)}';
}

String formatDuration(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds} sn';
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  if (hours > 0) return '$hours sa $minutes dk';
  return '$minutes dk';
}

String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String formatSpeedKmh(double? kmh) {
  if (kmh == null) return '—';
  return '${kmh.round()} km/s';
}

int speedKmh(double mps) => (mps * 3.6).round();
