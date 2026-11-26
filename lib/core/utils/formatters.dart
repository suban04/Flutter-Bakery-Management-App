import 'package:jantabackery/core/utils/currency_helper.dart';
import 'package:jantabackery/core/utils/date_helper.dart';

class AppFormatters {
  static String currency(num amount, {bool withSymbol = true}) =>
      CurrencyHelper.format(amount, withSymbol: withSymbol);

  static String plainNumber(num amount) =>
      CurrencyHelper.format(amount, withSymbol: false);

  static double parseCurrency(String raw) => CurrencyHelper.parse(raw);

  static String date(DateTime dt) => DateHelper.displayDate(dt);

  static String dateTime(DateTime dt) => DateHelper.displayDateTime(dt);

  static String dbDate(DateTime dt) => DateHelper.toDbDate(dt);

  static String monthPrefix(DateTime dt) => DateHelper.toMonthPrefix(dt);

  static String isoDate(String rawIso, {bool includeTime = true}) =>
      DateHelper.formatIso(rawIso, includeTime: includeTime);
}