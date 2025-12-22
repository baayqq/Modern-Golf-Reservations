import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _idrFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  static String idr(num value) => _idrFormat.format(value);
}