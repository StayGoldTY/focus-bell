String formatClock(int totalSeconds) {
  final safe = totalSeconds.clamp(0, 359999);
  final minutes = safe ~/ 60;
  final seconds = safe % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String formatDurationCompact(int seconds) {
  final safe = seconds.clamp(0, 359999);
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${minutes}min';
}
