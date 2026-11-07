import 'package:intl/intl.dart';

class Formatter {
  static final _rateFormat = NumberFormat('#,##0.00', 'uz_UZ');
  static final _bigFormat = NumberFormat('#,##0', 'uz_UZ');
  static final _percentFormat = NumberFormat('+0.00;-0.00', 'uz_UZ');

  static String rate(double value) {
    if (value >= 1000) return _bigFormat.format(value);
    return _rateFormat.format(value);
  }

  static String amount(double value) => _bigFormat.format(value);

  static String percent(double value) => '${_percentFormat.format(value)}%';

  static String diff(double value) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${_rateFormat.format(value)}';
  }

  static String dateTime(DateTime dt) {
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  static String timeOnly(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }
}
