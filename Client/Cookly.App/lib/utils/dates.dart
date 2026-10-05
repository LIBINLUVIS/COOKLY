/// Parses a backend timestamp. The API stores UTC but serializes some
/// DateTimes without an offset, so offset-less values are read as UTC.
DateTime? parseServerDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final hasOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
  return DateTime.tryParse(hasOffset ? value : '${value}Z')?.toLocal();
}

/// Whole calendar days from today to [date] (negative if in the past).
int calendarDaysFromToday(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final local = date.toLocal();
  final target = DateTime(local.year, local.month, local.day);
  return (target.difference(today).inHours / 24).round();
}

const _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatShortDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  return '${_monthAbbreviations[local.month - 1]} $day, ${local.year}';
}
