String formatMonthYear(DateTime dt) {
  return 'Tháng ${dt.month}/${dt.year}';
}

String formatDayHeader(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(date).inDays;

  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Hôm qua';
  return '${dt.day}/${dt.month}/${dt.year}';
}

String formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}