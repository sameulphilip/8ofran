class SlotId {
  SlotId._();

  static String build({
    required String priestId,
    required DateTime date,
    required TimeOfDayLike time,
  }) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '${priestId}_${'$y$m$d'}_$h$min';
  }

  static DateTime startsAt({
    required DateTime date,
    required TimeOfDayLike time,
  }) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class TimeOfDayLike {
  const TimeOfDayLike(this.hour, this.minute);

  final int hour;
  final int minute;

  static TimeOfDayLike fromDateTime(DateTime value) {
    return TimeOfDayLike(value.hour, value.minute);
  }
}
