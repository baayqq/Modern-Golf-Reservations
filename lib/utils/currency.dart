import 'package:intl/intl.dart';

/// Centralized currency formatting utilities.
class Formatters {
  static final NumberFormat _idrFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  /// Format a number to Indonesian Rupiah currency with no decimal digits.
  static String idr(num value) => _idrFormat.format(value);
}