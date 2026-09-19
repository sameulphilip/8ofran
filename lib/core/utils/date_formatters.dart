import 'package:intl/intl.dart';

class DateFormatters {
  DateFormatters._();

  static String longDate(DateTime date) {
    return DateFormat('EEEE d MMMM y', 'ar').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM y', 'ar').format(date);
  }

  static String time(DateTime date) {
    return DateFormat('h:mm a', 'ar').format(date);
  }

  static String hourOfDay(int hour) {
    return time(DateTime(2026, 1, 1, hour));
  }
}
