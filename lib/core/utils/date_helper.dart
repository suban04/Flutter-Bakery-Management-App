import 'package:intl/intl.dart';

class DateHelper {
  static String toDbDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static String toMonthPrefix(DateTime date) => DateFormat('yyyy-MM').format(date);

  static String displayDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  static String displayDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(date);

  static String formatIso(String rawIso, {bool includeTime = true}) {
    final parsed = DateTime.tryParse(rawIso);
    if (parsed == null) return rawIso;
    return includeTime
        ? DateFormat('dd MMM, hh:mm a').format(parsed)
        : DateFormat('dd MMM yyyy').format(parsed);
  }
}