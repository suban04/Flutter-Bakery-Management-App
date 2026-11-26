import 'package:intl/intl.dart';
import 'package:jantabackery/core/constants/app_settings.dart';

class CurrencyHelper {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_IN');

  static String format(num amount, {bool withSymbol = true}) {
    final formatted = _formatter.format(amount.round());
    return withSymbol ? '${AppSettings.currencySymbol}$formatted' : formatted;
  }

  static double parse(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}